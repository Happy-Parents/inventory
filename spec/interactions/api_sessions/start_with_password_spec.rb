RSpec.describe ApiSessions::StartWithPassword do
  let(:password) { 'Secret123!' }
  let!(:admin) { create(:admin, password:) }

  it 'starts a password session, matching the email case-insensitively' do
    tokens = described_class.call(email: admin.email.upcase, password:, device_name: 'iPhone')

    expect(tokens.api_session).to have_attributes(admin:, provider: 'password', device_name: 'iPhone')
    expect(tokens.access_token).to be_present
  end

  it 'raises for a wrong password' do
    expect { described_class.call(email: admin.email, password: 'wrong') }
      .to raise_error(ApiSessions::InvalidCredentials)
  end

  it 'raises for an unknown email' do
    expect { described_class.call(email: Faker::Internet.email, password:) }
      .to raise_error(ApiSessions::InvalidCredentials)
  end

  it 'raises for an OAuth-only admin without a password' do
    oauth_admin = create(:admin, password: nil)

    expect { described_class.call(email: oauth_admin.email, password: '') }
      .to raise_error(ApiSessions::InvalidCredentials)
  end
end
