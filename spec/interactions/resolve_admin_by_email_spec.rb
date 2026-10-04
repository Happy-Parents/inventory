RSpec.describe ResolveAdminByEmail do
  let(:email)  { Faker::Internet.email }
  let!(:admin) { create(:admin, email: email) }

  def auth_for(email)
    OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: '1', info: { email: email })
  end

  it 'finds the admin case-insensitively and reports the normalized email' do
    result = described_class.call(auth_for(email.upcase))

    expect(result.admin).to eq(admin)
    expect(result.email).to eq(email)
  end

  it 'raises for an email without an Admin row' do
    expect { described_class.call(auth_for(Faker::Internet.email)) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises when the provider supplies no email' do
    expect { described_class.call(auth_for(nil)) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
