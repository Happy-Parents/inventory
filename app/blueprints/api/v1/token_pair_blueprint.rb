module Api
  module V1
    # Renders an ApiTokens DTO in the OAuth 2-style shape mobile clients expect.
    class TokenPairBlueprint < Blueprinter::Base
      field(:token_type) { 'Bearer' }
      field :access_token
      field(:expires_in) { ApiAccessToken::TTL.to_i }
      field :refresh_token
      field(:refresh_token_expires_at) { |tokens| tokens.api_session.expires_at }
    end
  end
end
