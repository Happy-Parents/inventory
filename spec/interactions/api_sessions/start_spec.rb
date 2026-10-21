RSpec.describe ApiSessions::Start do
  let(:admin) { create(:admin) }

  it 'persists a session for the admin and returns its tokens' do
    tokens = described_class.call(admin:, provider: 'google_oauth2', device_name: 'iPhone')

    expect(tokens.api_session).to be_persisted
    expect(tokens.api_session).to have_attributes(admin:, provider: 'google_oauth2', device_name: 'iPhone')
    expect(tokens.api_session).to be_active
    expect(ApiAccessToken::Decode.call(tokens.access_token)['sid']).to eq(tokens.api_session.id)
  end

  it 'rejects an unknown provider' do
    expect { described_class.call(admin:, provider: 'myspace') }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
