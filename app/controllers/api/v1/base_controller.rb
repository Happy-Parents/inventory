module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods
      include Pundit::Authorization

      before_action :authenticate_admin!
      after_action :verify_authorized

      rescue_from ActiveRecord::RecordNotFound, with: -> { render_error(:not_found) }
      rescue_from ActionController::ParameterMissing, with: -> { render_error(:bad_request) }
      rescue_from Pundit::NotAuthorizedError, with: -> { render_error(:forbidden) }

      private

      attr_reader :current_admin, :access_token_claims

      def pundit_user = current_admin

      def authenticate_admin!
        @access_token_claims = authenticate_with_http_token { |token| decode_access_token(token) }
        @current_admin = Admin.find_by(id: access_token_claims['sub']) if access_token_claims
        return if current_admin

        headers['WWW-Authenticate'] = 'Bearer'
        render_error(:unauthorized)
      end

      def decode_access_token(token)
        ApiAccessToken::Decode.call(token)
      rescue ApiAccessToken::Invalid
        nil
      end

      def render_error(code, message = I18n.t(code, scope: 'api.errors'))
        render json: { error: { code:, message: } }, status: code
      end
    end
  end
end
