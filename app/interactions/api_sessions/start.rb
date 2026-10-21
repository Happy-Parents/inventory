module ApiSessions
  class Start
    extend Callable

    def initialize(admin:, provider:, device_name: nil)
      @api_session = ApiSession.new(admin:, provider:, device_name:)
    end

    def call = CreateTokenPair.call(api_session)

    private
    attr_reader :api_session
  end
end
