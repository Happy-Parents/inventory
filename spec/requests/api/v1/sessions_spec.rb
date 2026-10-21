require 'swagger_helper'

RSpec.describe 'API v1 sessions' do
  let(:password) { 'Secret123!' }
  let(:admin) { create(:admin, password:) }

  path '/session' do
    post 'Sign in' do
      tags 'Authentication'
      description 'Exchanges admin credentials for an access token (15 min) and a refresh token (30 days).'
      security []
      consumes 'application/json'
      produces 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        required: %w[email password],
        properties: {
          email: { type: :string, format: :email },
          password: { type: :string, format: :password },
          device_name: { type: :string, description: 'Label to recognise the session later, e.g. "Pixel 9"' }
        }
      }

      response '201', 'signed in' do
        schema '$ref' => '#/components/schemas/token_pair'
        let(:credentials) { { email: admin.email.upcase, password:, device_name: 'Pixel 9' } }

        run_test! do
          claims = ApiAccessToken::Decode.call(response.parsed_body['access_token'])
          expect(claims['sub']).to eq(admin.id)
          expect(ApiSession.find(claims['sid'])).to have_attributes(admin:, provider: 'password', device_name: 'Pixel 9')
        end
      end

      response '401', 'wrong email or password' do
        schema '$ref' => '#/components/schemas/error'
        let(:credentials) { { email: admin.email, password: 'wrong' } }

        run_test! do
          expect(response.parsed_body.dig('error', 'message')).to eq(I18n.t('api.errors.invalid_credentials'))
          expect(ApiSession.count).to eq(0)
        end
      end

      response '400', 'email or password missing' do
        schema '$ref' => '#/components/schemas/error'
        let(:credentials) { { email: admin.email } }

        run_test!
      end
    end

    delete 'Sign out' do
      tags 'Authentication'
      description 'Revokes the session the access token belongs to; its refresh token stops working. ' \
                  'Already issued access tokens stay valid until they expire.'
      produces 'application/json'

      let(:tokens) { start_api_session(admin) }

      response '204', 'session revoked' do
        let(:Authorization) { bearer(tokens) }

        run_test! do
          expect(tokens.api_session.reload).not_to be_active
        end
      end

      response '401', 'missing or invalid access token' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { 'Bearer invalid' }

        run_test!
      end
    end
  end

  path '/session/refresh' do
    post 'Refresh tokens' do
      tags 'Authentication'
      description 'Exchanges a refresh token for a new token pair. The presented refresh token is ' \
                  'consumed; reusing it later revokes the session.'
      security []
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object, required: %w[refresh_token], properties: { refresh_token: { type: :string } }
      }

      let(:tokens) { start_api_session(admin) }

      response '200', 'new token pair' do
        schema '$ref' => '#/components/schemas/token_pair'
        let(:body) { { refresh_token: tokens.refresh_token } }

        run_test! do
          expect(response.parsed_body['refresh_token']).not_to eq(tokens.refresh_token)
          expect(ApiAccessToken::Decode.call(response.parsed_body['access_token'])['sid']).to eq(tokens.api_session.id)
        end
      end

      response '401', 'refresh token invalid, expired, revoked or reused' do
        schema '$ref' => '#/components/schemas/error'
        let(:body) { { refresh_token: 'invalid' } }

        run_test! do
          expect(response.parsed_body.dig('error', 'message')).to eq(I18n.t('api.errors.invalid_refresh_token'))
        end
      end

      response '400', 'refresh token missing' do
        schema '$ref' => '#/components/schemas/error'
        let(:body) { {} }

        run_test!
      end
    end
  end

  describe 'token lifecycle' do
    let(:tokens) { start_api_session(admin) }

    def refresh(refresh_token)
      post '/api/v1/session/refresh', params: { refresh_token: }, as: :json
    end

    it 'revokes the session when a rotated refresh token is replayed' do
      refresh(tokens.refresh_token)
      newest = response.parsed_body['refresh_token']

      refresh(tokens.refresh_token)
      expect(response).to have_http_status(:unauthorized)

      refresh(newest)
      expect(response).to have_http_status(:unauthorized)
      expect(tokens.api_session.reload.revoked_at).to be_present
    end

    it 'rejects refreshing a signed-out session' do
      delete '/api/v1/session', headers: { 'Authorization' => bearer(tokens) }

      refresh(tokens.refresh_token)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects an expired refresh token' do
      tokens

      travel_to(ApiSession::REFRESH_TOKEN_TTL.from_now + 1.minute) { refresh(tokens.refresh_token) }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'ignores parameters that are not permitted' do
      post '/api/v1/session', params: { email: admin.email, password:, provider: 'apple', admin_id: SecureRandom.uuid },
                              as: :json

      expect(response).to have_http_status(:created)
      expect(ApiSession.sole).to have_attributes(admin:, provider: 'password')
    end

    it 'rejects a blank password as a missing parameter' do
      post '/api/v1/session', params: { email: admin.email, password: '' }, as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it 'signs out only the current session' do
      other = start_api_session(admin)

      delete '/api/v1/session', headers: { 'Authorization' => bearer(tokens) }
      refresh(other.refresh_token)

      expect(response).to have_http_status(:ok)
    end
  end
end
