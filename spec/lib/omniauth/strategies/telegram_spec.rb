RSpec.describe OmniAuth::Strategies::Telegram do
  let(:bot_token) { 'test-bot-token' }
  let(:strategy) { described_class.new(->(_env) { [200, {}, ['ok']] }, 'test_bot', bot_token) }

  # Signs a payload exactly the way Telegram does: every non-empty field
  # except `hash`, sorted, joined as key=value lines, HMAC-SHA256 keyed
  # with SHA256(bot_token).
  def signed_params(overrides = {}, sign_with: bot_token)
    params = {
      'id' => '42',
      'first_name' => 'Kyryl',
      'last_name' => 'O',
      'username' => 'kyryl',
      'photo_url' => 'https://t.me/i/userpic/320/kyryl.jpg',
      'auth_date' => Time.now.to_i.to_s
    }.merge(overrides).reject { |_, v| v.nil? }

    data = params.reject { |_, v| v.to_s.empty? }
    check_string = data.sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    secret = OpenSSL::Digest::SHA256.digest(sign_with)
    params.merge('hash' => OpenSSL::HMAC.hexdigest('SHA256', secret, check_string))
  end

  def with_params(params)
    allow(strategy).to receive(:request).and_return(double(params: params))
  end

  describe 'signature verification' do
    it 'accepts a correctly signed payload' do
      with_params(signed_params)

      expect(strategy.send(:valid_signature?)).to be(true)
    end

    it 'accepts a payload without optional fields' do
      with_params(signed_params({ 'username' => nil, 'last_name' => nil, 'photo_url' => nil }))

      expect(strategy.send(:valid_signature?)).to be(true)
    end

    it 'rejects a payload when a field is changed after signing' do
      with_params(signed_params.merge('id' => '43'))

      expect(strategy.send(:valid_signature?)).to be(false)
    end

    it 'rejects a payload when a signed field is dropped' do
      with_params(signed_params.except('username'))

      expect(strategy.send(:valid_signature?)).to be(false)
    end

    it 'rejects a payload signed with a different bot token' do
      with_params(signed_params(sign_with: 'attacker-token'))

      expect(strategy.send(:valid_signature?)).to be(false)
    end
  end

  describe 'auth_date expiry' do
    it 'treats a fresh payload as valid' do
      with_params(signed_params({ 'auth_date' => (Time.now.to_i - 10).to_s }))

      expect(strategy.send(:expired?)).to be(false)
    end

    it 'treats a payload older than the TTL as expired even when correctly signed' do
      params = signed_params({ 'auth_date' => (Time.now.to_i - 301).to_s })
      with_params(params)

      expect(strategy.send(:valid_signature?)).to be(true)
      expect(strategy.send(:expired?)).to be(true)
    end
  end

  describe '#callback_phase' do
    it 'fails before any crypto when required fields are missing' do
      with_params(signed_params.except('auth_date'))

      expect(strategy).not_to receive(:valid_signature?)
      expect(strategy).to receive(:fail!).with(:missing_fields)

      strategy.callback_phase
    end

    it 'fails on an invalid signature' do
      with_params(signed_params.merge('hash' => 'f' * 64))

      expect(strategy).to receive(:fail!).with(:invalid_signature)

      strategy.callback_phase
    end

    it 'fails on an expired payload' do
      with_params(signed_params({ 'auth_date' => (Time.now.to_i - 301).to_s }))

      expect(strategy).to receive(:fail!).with(:session_expired)

      strategy.callback_phase
    end
  end

  describe 'auth hash mapping' do
    it 'exposes the Telegram user id as uid and profile fields as info' do
      with_params(signed_params)

      expect(strategy.uid).to eq('42')
      expect(strategy.info).to eq(
        name: 'Kyryl O',
        nickname: 'kyryl',
        image: 'https://t.me/i/userpic/320/kyryl.jpg'
      )
    end
  end
end
