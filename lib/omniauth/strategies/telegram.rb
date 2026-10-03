require 'omniauth'
require 'openssl'

module OmniAuth
  module Strategies
    class Telegram
      include OmniAuth::Strategy

      args %i[bot_name bot_token]
      option :bot_name, nil
      option :bot_token, nil
      option :auth_date_ttl, 300 # seconds; strict — it's an admin panel

      # Every field the widget may send, except the signature itself.
      DATA_FIELDS = %w[auth_date first_name id last_name photo_url username].freeze

      # Fallback for anyone who hits /admin/auth/telegram directly;
      # the login page embeds this same widget (Phase 6).
      def request_phase
        html = <<~HTML
          <!DOCTYPE html>
          <html><head><title>Sign in with Telegram</title></head><body>
            <script async src="https://telegram.org/js/telegram-widget.js?22"
                    data-telegram-login="#{options.bot_name}"
                    data-size="large"
                    data-auth-url="#{callback_url}"></script>
          </body></html>
        HTML
        Rack::Response.new(html, 200, 'content-type' => 'text/html').finish
      end

      def callback_phase
        return fail!(:missing_fields)    if request.params['id'].to_s.empty? ||
                                            request.params['hash'].to_s.empty? ||
                                            request.params['auth_date'].to_s.empty?
        return fail!(:invalid_signature) unless valid_signature?
        return fail!(:session_expired)   if expired?

        super
      end

      uid { request.params['id'].to_s }

      info do
        {
          name: [ request.params['first_name'],
                 request.params['last_name'] ].compact.join(' '),
          nickname: request.params['username'],
          image: request.params['photo_url']
        }
      end

      extra { { raw_info: request.params.slice(*DATA_FIELDS) } }

      private

      def valid_signature?
        data = request.params.slice(*DATA_FIELDS)
                             .reject { |_, v| v.to_s.empty? }
        check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
        secret = OpenSSL::Digest::SHA256.digest(options.bot_token.to_s)
        hmac = OpenSSL::HMAC.hexdigest('SHA256', secret, check_string)
        Rack::Utils.secure_compare(hmac, request.params['hash'].to_s)
      end

      def expired?
        (Time.now.to_i - request.params['auth_date'].to_i) > options.auth_date_ttl
      end
    end
  end
end
