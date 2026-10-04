RSpec.describe ResolveAdminByTelegram do
  def auth_for(uid, nickname: 'tg_nick')
    OmniAuth::AuthHash.new(provider: 'telegram', uid: uid, info: { nickname: nickname })
  end

  context 'when an admin has the telegram account linked' do
    let!(:admin) { create(:admin, telegram_id: 42, telegram_username: 'old_nick') }

    it 'returns the admin' do
      result = described_class.call(auth_for('42'))

      expect(result.admin).to eq(admin)
    end

    it 'refreshes the stored username from the provider nickname' do
      described_class.call(auth_for('42', nickname: 'new_nick'))

      expect(admin.reload.telegram_username).to eq('new_nick')
    end
  end

  it 'raises when no admin is linked to the telegram id' do
    expect { described_class.call(auth_for('999')) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
