class ResolveAdminByEmail
  extend Callable

  def initialize(omniauth_hash)
    @omniauth_hash = omniauth_hash
  end

  def call
    EmailSignInResult.new(admin:, email:)
  end

  private
  attr_reader :omniauth_hash

  def admin = Admin.find_by!(email: email)
  def email = omniauth_hash.info.email.to_s.downcase
end
