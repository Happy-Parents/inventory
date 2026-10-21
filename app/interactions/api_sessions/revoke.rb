module ApiSessions
  class Revoke
    extend Callable

    def initialize(api_session)
      @api_session = api_session
    end

    def call
      api_session.update!(revoked_at: Time.current) unless api_session.revoked_at
    end

    private
    attr_reader :api_session
  end
end
