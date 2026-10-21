module ApiSessions
  class Refresh
    extend Callable

    def initialize(refresh_token)
      @session_id, @secret = refresh_token.to_s.split('.', 2)
    end

    # Presenting anything but the session's current refresh token means an already
    # refreshed token is being replayed — possibly stolen — so the whole session is
    # revoked and both the attacker and the real device have to sign in again.
    def call
      raise InvalidRefreshToken unless api_session

      # The lock serialises concurrent refreshes of one session, so the same
      # token can't be refreshed twice.
      api_session.with_lock { rotate_or_revoke } || raise(InvalidRefreshToken)
    end

    private
    attr_reader :session_id, :secret

    def api_session = @api_session ||= ApiSession.find_by(id: session_id)

    def rotate_or_revoke
      return unless api_session.active?
      return CreateTokenPair.call(api_session) if VerifyRefreshSecret.call(api_session, secret)

      Revoke.call(api_session)
      Rails.logger.warn("Refresh token reuse detected, revoked API session #{api_session.id}")
      nil
    end
  end
end
