module ApiHelpers
  def start_api_session(admin = create(:admin))
    ApiSessions::Start.call(admin:, provider: 'password')
  end

  def bearer(tokens) = "Bearer #{tokens.access_token}"
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
  config.include ApiHelpers, type: :controller
end
