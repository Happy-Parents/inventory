RSpec.describe ConnectTelegram do
  let(:admin) { create(:admin) }

  def auth_for(uid, nickname: 'tg_nick')
    OmniAuth::AuthHash.new(provider: 'telegram', uid: uid, info: { nickname: nickname })
  end

  it 'stores the telegram id and username on the admin' do
    described_class.call(admin, auth_for('42', nickname: 'tg_nick'))

    admin.reload
    expect(admin.telegram_id).to eq(42)
    expect(admin.telegram_username).to eq('tg_nick')
  end

  it 'raises when the telegram account is already linked to another admin' do
    create(:admin, telegram_id: 42)

    expect { described_class.call(admin, auth_for('42')) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
