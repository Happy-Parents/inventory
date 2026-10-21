module ApiSessions
  class StartWithPassword
    extend Callable

    def initialize(email:, password:, device_name: nil)
      @email = email
      @password = password
      @device_name = device_name
    end

    def call
      raise InvalidCredentials unless admin&.valid_password?(password)

      Start.call(admin:, provider: 'password', device_name:)
    end

    private
    attr_reader :email, :password, :device_name

    def admin = @admin ||= Admin.find_for_authentication(email: email.to_s)
  end
end
