module ApiAccessToken
  # Roles are left out: authorization reads them fresh from the database.
  TTL = 15.minutes
  ISSUER = 'hp-inventory'
  AUDIENCE = 'hp-inventory-api'
  ALGORITHM = 'HS256'
  REQUIRED_CLAIMS = %w[sub sid iat exp jti iss aud].freeze

  # Кotating ecret_key_base invalidates outstanding access tokens (not refresh tokens).
  def self.signing_key = Rails.application.key_generator.generate_key('api access token', 32)
end
