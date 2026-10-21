RSpec.describe ApiSessions::VerifyRefreshSecret do
  let(:tokens) { ApiSessions::Start.call(admin: create(:admin), provider: 'password') }
  let(:api_session) { tokens.api_session }
  let(:secret) { tokens.refresh_token.delete_prefix("#{api_session.id}.") }

  it 'accepts the current secret' do
    expect(described_class.call(api_session, secret)).to be(true)
  end

  it 'rejects any other secret' do
    expect(described_class.call(api_session, "#{secret}x")).to be(false)
    expect(described_class.call(api_session, tokens.refresh_token)).to be(false)
  end

  it 'rejects a blank secret' do
    expect(described_class.call(api_session, nil)).to be(false)
    expect(described_class.call(api_session, '')).to be(false)
  end

  it 'compares digests in constant time' do
    allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original

    described_class.call(api_session, secret)

    expect(ActiveSupport::SecurityUtils).to have_received(:secure_compare)
      .with(api_session.refresh_token_digest, ApiSession.digest(secret))
  end
end
