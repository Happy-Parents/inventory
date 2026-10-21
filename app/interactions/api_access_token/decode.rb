module ApiAccessToken
  class Decode
    extend Callable

    def initialize(token)
      @token = token
    end

    def call
      claims, = JWT.decode(token, ApiAccessToken.signing_key, true,
                           algorithms: [ ALGORITHM ], iss: ISSUER, verify_iss: true,
                           aud: AUDIENCE, verify_aud: true, required_claims: REQUIRED_CLAIMS)
      claims
    rescue JWT::DecodeError
      raise Invalid
    end

    private
    attr_reader :token
  end
end
