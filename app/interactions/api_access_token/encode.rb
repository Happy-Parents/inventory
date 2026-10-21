module ApiAccessToken
  class Encode
    extend Callable

    def initialize(api_session, now: Time.current)
      @api_session = api_session
      @now = now
    end

    def call = JWT.encode(payload, ApiAccessToken.signing_key, ALGORITHM)

    private
    attr_reader :api_session, :now

    def payload
      {
        sub: api_session.admin_id,
        sid: api_session.id,
        iat: now.to_i,
        exp: (now + TTL).to_i,
        jti: SecureRandom.uuid,
        iss: ISSUER,
        aud: AUDIENCE
      }
    end
  end
end
