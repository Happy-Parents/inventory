class ConnectTelegram
  extend Callable

  def initialize(admin, omniauth_hash)
    @omniauth_hash = omniauth_hash
    @admin         = admin
  end

  def call
    admin.update!(
      telegram_id: omniauth_hash.uid,
      telegram_username: omniauth_hash.info.nickname
      )
  end

  private
  attr_reader :omniauth_hash, :admin
end
