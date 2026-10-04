class ResolveAdminByTelegram
  extend Callable

  def initialize(omniauth_hash)
    @omniauth_hash = omniauth_hash
  end

  def call
    admin.update(telegram_username: omniauth_hash.info.nickname)
    TelegramSignInResult.new(admin:)
  end

  private
  attr_reader :omniauth_hash

  def admin = Admin.find_by!(telegram_id: omniauth_hash.uid)
end
