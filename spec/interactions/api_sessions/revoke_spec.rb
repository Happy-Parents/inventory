RSpec.describe ApiSessions::Revoke do
  let(:api_session) { ApiSessions::Start.call(admin: create(:admin), provider: 'password').api_session }

  it 'deactivates the session' do
    described_class.call(api_session)

    expect(api_session.reload).not_to be_active
    expect(api_session.revoked_at).to be_present
  end

  it 'keeps the original revocation time when revoked again' do
    described_class.call(api_session)
    revoked_at = api_session.revoked_at

    travel_to(1.hour.from_now) { described_class.call(api_session) }

    expect(api_session.reload.revoked_at).to eq(revoked_at)
  end
end
