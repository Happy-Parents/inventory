RSpec.describe ApiSessions::Refresh do
  let(:tokens) { ApiSessions::Start.call(admin: create(:admin), provider: 'password') }
  let(:api_session) { tokens.api_session }

  it 'rotates the refresh token and issues a new access token for the same session' do
    refreshed = described_class.call(tokens.refresh_token)

    expect(refreshed.api_session).to eq(api_session)
    expect(refreshed.refresh_token).not_to eq(tokens.refresh_token)
    expect(refreshed.access_token).not_to eq(tokens.access_token)
  end

  it 'revokes the session when an already rotated refresh token is reused' do
    described_class.call(tokens.refresh_token)

    expect { described_class.call(tokens.refresh_token) }.to raise_error(ApiSessions::InvalidRefreshToken)
    expect(api_session.reload.revoked_at).to be_present
  end

  it 'rejects revoked and expired sessions without rotating' do
    ApiSessions::Revoke.call(api_session)

    expect { described_class.call(tokens.refresh_token) }.to raise_error(ApiSessions::InvalidRefreshToken)

    other = ApiSessions::Start.call(admin: create(:admin), provider: 'password')
    other.api_session.update!(expires_at: 1.minute.ago)

    expect { described_class.call(other.refresh_token) }.to raise_error(ApiSessions::InvalidRefreshToken)
  end

  it 'rejects malformed and unknown tokens' do
    [ nil, '', 'garbage', "#{SecureRandom.uuid}.secret", "#{api_session.id}." ].each do |token|
      expect { described_class.call(token) }.to raise_error(ApiSessions::InvalidRefreshToken)
    end
  end
end
