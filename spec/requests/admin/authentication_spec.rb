RSpec.describe 'Admin authentication' do
  let(:password) { 'Secret123!' }
  let!(:admin) { create(:admin, email: 'owner@example.com', password: password) }

  before { OmniAuth.config.test_mode = true }

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    Rails.application.env_config.delete('omniauth.auth')
  end

  # Devise keeps the signed-in admin's id in the session under the warden key,
  # which lets these specs prove both login methods resolve to the same record.
  def warden_admin_id
    session['warden.user.admin.key']&.dig(0, 0)
  end

  def mock_google_auth(email)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '123456789012345678901',
      info: { email: email, name: 'Test Admin' }
    )
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  describe 'password sign-in' do
    it 'signs in with valid credentials' do
      post '/admin/login', params: { admin: { email: admin.email, password: password } }

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(admin.id)
    end

    it 'rejects an invalid password' do
      post '/admin/login', params: { admin: { email: admin.email, password: 'wrong' } }

      expect(warden_admin_id).to be_nil
    end

    it 'rejects an SSO-only admin (no password set) even with a blank password' do
      sso_only = create(:admin, email: 'sso.only@example.com', password: nil)

      post '/admin/login', params: { admin: { email: sso_only.email, password: '' } }

      expect(warden_admin_id).to be_nil
    end

    it 'keeps unauthenticated visitors out of the admin panel' do
      get '/admin'

      expect(response).to redirect_to('/admin/login')
    end
  end

  describe 'Google sign-in' do
    it 'signs a whitelisted email into the same account as password login' do
      mock_google_auth(admin.email)

      get '/admin/auth/google_oauth2/callback'

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(admin.id)
    end

    it 'signs in an SSO-only admin' do
      sso_only = create(:admin, email: 'sso.only@example.com', password: nil)
      mock_google_auth(sso_only.email)

      get '/admin/auth/google_oauth2/callback'

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(sso_only.id)
    end

    it 'matches the Google email case-insensitively' do
      mock_google_auth(admin.email.upcase)

      get '/admin/auth/google_oauth2/callback'

      expect(warden_admin_id).to eq(admin.id)
    end

    it 'rejects an email that has no Admin row and does not create one' do
      mock_google_auth('stranger@gmail.com')

      expect { get '/admin/auth/google_oauth2/callback' }.not_to change(Admin, :count)

      expect(response).to redirect_to('/admin/login')
      expect(flash[:alert]).to include('stranger@gmail.com')
      expect(warden_admin_id).to be_nil
    end
  end
end
