module ApiSessions
  class VerifyRefreshSecret
    extend Callable

    def initialize(api_session, secret)
      @api_session = api_session
      @secret = secret
    end

    def call
      secret.present? && ActiveSupport::SecurityUtils.secure_compare(
                          api_session.refresh_token_digest,
                          ApiSession.digest(secret)
                        )
    end

    private
    attr_reader :api_session, :secret
  end
end
