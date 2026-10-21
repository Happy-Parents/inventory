require 'swagger_helper'

RSpec.describe 'API v1 me' do
  let(:tokens) { start_api_session }

  path '/me' do
    get 'Current admin' do
      tags 'Authentication'
      produces 'application/json'

      response '200', 'the admin the access token was issued to' do
        schema '$ref' => '#/components/schemas/admin'
        let(:Authorization) { bearer(tokens) }

        run_test! do
          expect(response.parsed_body).to include('id' => tokens.api_session.admin_id, 'role' => 'manager')
        end
      end

      response '401', 'missing, invalid or expired access token' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { 'Bearer not-a-jwt' }

        run_test! do
          expect(response.headers['WWW-Authenticate']).to eq('Bearer')
          expect(response.parsed_body.dig('error', 'code')).to eq('unauthorized')
        end
      end
    end
  end

  def get_me(authorization = bearer(tokens))
    get '/api/v1/me', headers: { 'Authorization' => authorization }.compact
  end

  it 'rejects requests without an Authorization header' do
    get_me(nil)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects an access token once it has expired' do
    tokens

    travel_to(ApiAccessToken::TTL.from_now + 1.second) { get_me }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'keeps accepting an access token of a revoked session until it expires (stateless validation)' do
    ApiSessions::Revoke.call(tokens.api_session)

    get_me

    expect(response).to have_http_status(:ok)
  end

  it 'rejects the token of an admin that no longer exists' do
    tokens.api_session.admin.destroy!

    get_me

    expect(response).to have_http_status(:unauthorized)
  end

  it 'ignores browser sessions: the API is token-only' do
    sign_in create(:admin)

    get_me(nil)

    expect(response).to have_http_status(:unauthorized)
  end
end
