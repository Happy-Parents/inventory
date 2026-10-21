module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_admin!, only: %i[create refresh]
      skip_after_action :verify_authorized

      rate_limit to: 10, within: 3.minutes, only: :create, name: 'sign-in',
                 with: -> { render_error(:too_many_requests) }
      rate_limit to: 30, within: 3.minutes, only: :refresh, name: 'refresh',
                 with: -> { render_error(:too_many_requests) }

      def create
        tokens = ApiSessions::StartWithPassword.call(**sign_in_params)
        render_tokens(tokens, status: :created)
      rescue ApiSessions::InvalidCredentials
        render_error(:unauthorized, I18n.t('api.errors.invalid_credentials'))
      end

      def refresh
        render_tokens(ApiSessions::Refresh.call(refresh_params), status: :ok)
      rescue ApiSessions::InvalidRefreshToken
        render_error(:unauthorized, I18n.t('api.errors.invalid_refresh_token'))
      end

      def destroy
        ApiSessions::Revoke.call(current_admin.api_sessions.find(access_token_claims['sid']))
        head :no_content
      end

      private

      def sign_in_params
        params.expect(session: %i[email password device_name])
              .tap { it.require(%i[email password]) }
              .to_h.symbolize_keys
      end

      def refresh_params
        params.expect(session: %i[refresh_token]).require(:refresh_token)
      end

      def render_tokens(tokens, status:)
        render json: TokenPairBlueprint.render_as_hash(tokens), status:
      end
    end
  end
end
