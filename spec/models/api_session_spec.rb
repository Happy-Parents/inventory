RSpec.describe ApiSession do
  let(:admin) { create(:admin) }
  let(:api_session) { ApiSessions::Start.call(admin:, provider: 'password').api_session }

  it { is_expected.to belong_to(:admin) }
  it { is_expected.to validate_inclusion_of(:provider).in_array(described_class::PROVIDERS) }

  describe '.digest' do
    it 'is a SHA-256 hex digest' do
      expect(described_class.digest('secret')).to eq(OpenSSL::Digest::SHA256.hexdigest('secret'))
    end
  end

  describe 'activity' do
    it 'is active until revoked' do
      expect(api_session).to be_active

      api_session.update!(revoked_at: Time.current)

      expect(api_session).not_to be_active
    end

    it 'is inactive once expired' do
      api_session.update!(expires_at: 1.minute.ago)

      expect(api_session).not_to be_active
    end

    it 'scopes to active sessions only' do
      revoked = ApiSessions::Start.call(admin:, provider: 'password').api_session
      revoked.update!(revoked_at: Time.current)
      expired = ApiSessions::Start.call(admin:, provider: 'password').api_session
      expired.update!(expires_at: 1.minute.ago)

      expect(described_class.active).to contain_exactly(api_session)
    end
  end

  it 'is deleted together with its admin' do
    api_session

    admin.destroy!

    expect(described_class.exists?(api_session.id)).to be(false)
  end
end
