RSpec.describe ApiAccessToken::Encode do
  let(:api_session) { ApiSessions::Start.call(admin: create(:admin), provider: 'password').api_session }
  let(:now) { Time.zone.parse('2026-10-20 12:00:00') }

  def unverified_claims(token) = JWT.decode(token, nil, false).first
  def header(token) = JWT.decode(token, nil, false).last

  it 'signs an HS256 JWT with the shared signing key' do
    token = described_class.call(api_session)

    expect(header(token)).to include('alg' => 'HS256')
    expect { JWT.decode(token, ApiAccessToken.signing_key, true, algorithms: [ 'HS256' ]) }.not_to raise_error
  end

  it 'carries only identifiers and standard claims' do
    claims = unverified_claims(described_class.call(api_session, now:))

    expect(claims).to match(
      'sub' => api_session.admin_id,
      'sid' => api_session.id,
      'iat' => now.to_i,
      'exp' => (now + ApiAccessToken::TTL).to_i,
      'jti' => a_string_matching(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/),
      'iss' => ApiAccessToken::ISSUER,
      'aud' => ApiAccessToken::AUDIENCE
    )
  end

  it 'defaults the issue time to now' do
    freeze_time do
      expect(unverified_claims(described_class.call(api_session))['iat']).to eq(Time.current.to_i)
    end
  end

  it 'gives every token a unique jti' do
    jtis = Array.new(2) { unverified_claims(described_class.call(api_session))['jti'] }

    expect(jtis.uniq.size).to eq(2)
  end
end
