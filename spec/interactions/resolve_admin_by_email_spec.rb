RSpec.describe ResolveAdminByEmail do
  let!(:admin) { create(:admin, email: 'owner@example.com') }

  def auth_for(email)
    OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: '1', info: { email: email })
  end

  it 'finds the admin case-insensitively and reports the normalized email' do
    result = described_class.call(auth_for('OWNER@example.com'))

    expect(result.admin).to eq(admin)
    expect(result.email).to eq('owner@example.com')
  end

  it 'raises for an email without an Admin row' do
    expect { described_class.call(auth_for('stranger@example.com')) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises when the provider supplies no email' do
    expect { described_class.call(auth_for(nil)) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
