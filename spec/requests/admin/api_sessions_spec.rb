RSpec.describe 'Admin API sessions' do
  let(:owner) { create(:admin, email: 'mobile.user@example.com') }

  def start_session(device_name) = ApiSessions::Start.call(admin: owner, provider: 'password', device_name:).api_session

  context 'as a super admin' do
    before { sign_in create(:admin, :super_admin) }

    it 'is listed in the settings menu' do
      get '/admin'

      expect(response.body).to include('href="/admin/api_sessions"', 'API сесії')
    end

    it 'lists active sessions only' do
      start_session('Pixel 9')
      start_session('Revoked phone').then { ApiSessions::Revoke.call(it) }
      start_session('Expired phone').update!(expires_at: 1.minute.ago)

      get '/admin/api_sessions'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Pixel 9', owner.email)
      expect(response.body).not_to include('Revoked phone', 'Expired phone')
    end

    it 'filters sessions by admin email' do
      start_session('Pixel 9')
      other = create(:admin, email: 'other.user@example.com')
      ApiSessions::Start.call(admin: other, provider: 'password', device_name: 'iPhone')

      get '/admin/api_sessions', params: { q: { admin_id_eq: other.id } }

      expect(response.body).to match(%r{<option [^>]*value="#{other.id}"[^>]*>other.user@example.com</option>})
      expect(response.body).to include('iPhone')
      expect(response.body).not_to include('Pixel 9')
    end

    it 'offers only admins with active sessions in the admin filter' do
      start_session('Pixel 9')
      create(:admin, email: 'no.sessions@example.com')
      revoked_only = create(:admin, email: 'revoked.only@example.com')
      ApiSessions::Revoke.call(ApiSessions::Start.call(admin: revoked_only, provider: 'password').api_session)

      get '/admin/api_sessions'

      options = response.body[%r{<select[^>]*q_admin_id.*?</select>}m]
      expect(options).to include(owner.email)
      expect(options).not_to include('no.sessions@example.com', 'revoked.only@example.com')
    end

    it 'offers only providers of active sessions in the provider filter' do
      start_session('Pixel 9')
      ApiSessions::Start.call(admin: owner, provider: 'google_oauth2')
      ApiSessions::Revoke.call(ApiSessions::Start.call(admin: owner, provider: 'github').api_session)

      get '/admin/api_sessions'

      options = response.body[%r{<select[^>]*q_provider.*?</select>}m].scan(/<option value="([^"]+)"/).flatten
      expect(options).to eq(%w[google_oauth2 password])
    end

    it 'deletes a session by revoking it' do
      api_session = start_session('Pixel 9')

      delete "/admin/api_sessions/#{api_session.id}"

      expect(response).to redirect_to('/admin/api_sessions')
      expect(api_session.reload).not_to be_active
    end

    it 'deletes several sessions at once' do
      selected = [ start_session('Pixel 9'), start_session('iPhone') ]
      kept = start_session('iPad')

      post '/admin/api_sessions/batch_action',
           params: { batch_action: 'destroy', collection_selection: selected.map(&:id) }

      expect(response).to redirect_to('/admin/api_sessions')
      expect(selected.map { it.reload.active? }).to all(be(false))
      expect(kept.reload).to be_active
    end
  end

  context 'as a manager' do
    before { sign_in create(:admin) }

    it 'is not in the menu' do
      get '/admin'

      expect(response.body).not_to include('/admin/api_sessions')
    end

    it 'cannot list sessions' do
      get '/admin/api_sessions'

      expect(response).to redirect_to('/admin')
      expect(flash[:error]).to be_present
    end

    it 'cannot delete a session' do
      api_session = start_session('Pixel 9')

      delete "/admin/api_sessions/#{api_session.id}"

      expect(response).to redirect_to('/admin')
      expect(api_session.reload).to be_active
    end
  end
end
