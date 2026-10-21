module ApiSessions
  class CreateTokenPair
    extend Callable

    def initialize(api_session)
      @api_session = api_session
    end

    def call
      api_session.update!(
                        refresh_token_digest:,
                        expires_at: ApiSession::REFRESH_TOKEN_TTL.from_now)

      ApiTokens.new(api_session:,
                    access_token:,
                    refresh_token: "#{api_session.id}.#{secret}")
    end

    private
    attr_reader :api_session

    def secret = @secret ||= SecureRandom.base58(32)
      def access_token  = @access_token ||= ApiAccessToken::Encode.call(api_session)
        def refresh_token_digest = @refresh_token_digest ||= ApiSession.digest(secret)
  end
end
