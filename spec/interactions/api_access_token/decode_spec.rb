RSpec.describe ApiAccessToken::Decode do
  let(:api_session) { ApiSessions::Start.call(admin: create(:admin), provider: 'password').api_session }
  let(:token) { ApiAccessToken::Encode.call(api_session) }

  def forge(changes = {}, without: [], key: ApiAccessToken.signing_key, algorithm: 'HS256')
    payload = JWT.decode(token, nil, false).first.merge(changes).except(*without)
    JWT.encode(payload, key, algorithm)
  end

  it 'returns the claims of a valid token' do
    expect(described_class.call(token)).to include('sub' => api_session.admin_id, 'sid' => api_session.id)
  end

  it 'rejects an expired token' do
    token

    travel_to(ApiAccessToken::TTL.from_now + 1.second) do
      expect { described_class.call(token) }.to raise_error(ApiAccessToken::Invalid)
    end
  end

  {
    'a wrong signature' => -> { forge(key: 'x' * 32) },
    'a wrong issuer' => -> { forge({ 'iss' => 'someone-else' }) },
    'a wrong audience' => -> { forge({ 'aud' => 'another-api' }) },
    'the none algorithm' => -> { forge(key: nil, algorithm: 'none') },
    'another HMAC algorithm' => -> { forge(algorithm: 'HS512') },
    'a missing required claim' => -> { forge(without: %w[sid]) },
    'a malformed string' => -> { 'garbage' },
    'nil' => -> { nil }
  }.each do |description, build_token|
    it "rejects #{description}" do
      expect { described_class.call(instance_exec(&build_token)) }.to raise_error(ApiAccessToken::Invalid)
    end
  end
end
