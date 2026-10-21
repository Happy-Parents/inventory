RSpec.describe ApiSessions::CreateTokenPair do
  let(:tokens) { ApiSessions::Start.call(admin: create(:admin), provider: 'password') }
  let(:api_session) { tokens.api_session }

  def secret_of(refresh_token) = refresh_token.delete_prefix("#{api_session.id}.")

  it 'stores only the digest of the refresh token secret' do
    expect(api_session.reload.refresh_token_digest).to eq(ApiSession.digest(secret_of(tokens.refresh_token)))
    expect(ApiSession.where(refresh_token_digest: [ tokens.refresh_token, secret_of(tokens.refresh_token) ]))
      .to be_empty
  end

  it 'issues an access token for the session' do
    claims = ApiAccessToken::Decode.call(tokens.access_token)

    expect(claims).to include('sub' => api_session.admin_id, 'sid' => api_session.id)
  end

  it 'rotates the refresh token, invalidating the previous one' do
    rotated = described_class.call(api_session)

    expect(rotated.refresh_token).not_to eq(tokens.refresh_token)
    expect(rotated.refresh_token).to start_with("#{api_session.id}.")
    expect(ApiSessions::VerifyRefreshSecret.call(api_session, secret_of(tokens.refresh_token))).to be(false)
    expect(ApiSessions::VerifyRefreshSecret.call(api_session, secret_of(rotated.refresh_token))).to be(true)
  end

  it 'extends the session by the refresh token TTL' do
    tokens

    travel_to(1.day.from_now) do
      described_class.call(api_session)

      expect(api_session.expires_at).to be_within(1.second).of(ApiSession::REFRESH_TOKEN_TTL.from_now)
    end
  end
end
