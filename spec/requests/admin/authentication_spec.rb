RSpec.describe 'Admin authentication' do
  let(:password) { 'Secret123!' }
  let!(:admin) { create(:admin, email: 'owner@example.com', password: password) }

  before { OmniAuth.config.test_mode = true }

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.mock_auth[:telegram] = nil
    Rails.application.env_config.delete('omniauth.auth')
  end

  # Devise keeps the signed-in admin's id in the session under the warden key,
  # which lets these specs prove both login methods resolve to the same record.
  def warden_admin_id
    session['warden.user.admin.key']&.dig(0, 0)
  end

  def mock_oauth(provider, email)
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid: '123456789012345678901',
      info: { email: email, name: 'Test Admin' }
    )
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[provider]
  end

  # Telegram's payload carries no email — only the numeric Telegram user id
  # (uid) and profile fields. Sign-in matches admins.telegram_id alone.
  def mock_telegram(uid, username: 'tg_user')
    OmniAuth.config.mock_auth[:telegram] = OmniAuth::AuthHash.new(
      provider: 'telegram',
      uid: uid.to_s,
      info: { name: 'Test Admin', nickname: username }
    )
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:telegram]
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
      mock_oauth(:google_oauth2, admin.email)

      get '/admin/auth/google_oauth2/callback'

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(admin.id)
    end

    it 'signs in an SSO-only admin' do
      sso_only = create(:admin, email: 'sso.only@example.com', password: nil)
      mock_oauth(:google_oauth2, sso_only.email)

      get '/admin/auth/google_oauth2/callback'

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(sso_only.id)
    end

    it 'matches the Google email case-insensitively' do
      mock_oauth(:google_oauth2, admin.email.upcase)

      get '/admin/auth/google_oauth2/callback'

      expect(warden_admin_id).to eq(admin.id)
    end

    it 'rejects an email that has no Admin row and does not create one' do
      mock_oauth(:google_oauth2, 'stranger@gmail.com')

      expect { get '/admin/auth/google_oauth2/callback' }.not_to change(Admin, :count)

      expect(response).to redirect_to('/admin/login')
      expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.not_authorized'))
      expect(warden_admin_id).to be_nil
    end
  end

  describe 'GitHub sign-in' do
    it 'signs a whitelisted email into the same account as password login' do
      mock_oauth(:github, admin.email)

      get '/admin/auth/github/callback'

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(admin.id)
    end

    it 'signs in an SSO-only admin' do
      sso_only = create(:admin, email: 'sso.only@example.com', password: nil)
      mock_oauth(:github, sso_only.email)

      get '/admin/auth/github/callback'

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(sso_only.id)
    end

    it 'matches the GitHub email case-insensitively' do
      mock_oauth(:github, admin.email.upcase)

      get '/admin/auth/github/callback'

      expect(warden_admin_id).to eq(admin.id)
    end

    it 'rejects an email that has no Admin row and does not create one' do
      mock_oauth(:github, 'stranger@github.com')

      expect { get '/admin/auth/github/callback' }.not_to change(Admin, :count)

      expect(response).to redirect_to('/admin/login')
      expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.not_authorized'))
      expect(warden_admin_id).to be_nil
    end

    # GitHub returns no email when the user:email scope is missing or the
    # account has none — that must never match an Admin row.
    it 'rejects a sign-in when GitHub provides no email' do
      mock_oauth(:github, nil)

      expect { get '/admin/auth/github/callback' }.not_to change(Admin, :count)

      expect(response).to redirect_to('/admin/login')
      expect(warden_admin_id).to be_nil
    end
  end

  describe 'Telegram sign-in' do
    it 'signs a linked admin into the same account as password login' do
      admin.update!(telegram_id: 42, telegram_username: 'old_name')
      mock_telegram(42, username: 'new_name')

      get '/admin/auth/telegram/callback'

      expect(response).to redirect_to('/admin')
      expect(warden_admin_id).to eq(admin.id)
      expect(admin.reload.telegram_username).to eq('new_name')
    end

    it 'rejects an unlinked Telegram account and does not create an admin' do
      mock_telegram(999)

      expect { get '/admin/auth/telegram/callback' }.not_to change(Admin, :count)

      expect(response).to redirect_to('/admin/login')
      expect(flash[:alert]).to eq(I18n.t('devise.omniauth_callbacks.telegram_not_linked'))
      expect(warden_admin_id).to be_nil
    end
  end

  describe 'Telegram account linking' do
    it 'links Telegram to the signed-in admin' do
      sign_in admin
      mock_telegram(42, username: 'kyryl')

      get '/admin/auth/telegram/callback'

      expect(response).to redirect_to('/admin/my_account')
      expect(admin.reload.telegram_id).to eq(42)
      expect(admin.telegram_username).to eq('kyryl')
    end

    it 'refuses to link a Telegram account already taken by another admin' do
      create(:admin, email: 'other@example.com', telegram_id: 42)
      sign_in admin
      mock_telegram(42)

      get '/admin/auth/telegram/callback'

      expect(admin.reload.telegram_id).to be_nil
      expect(flash[:alert]).to include('already linked to another admin')
    end

    it 'renders My Account with the widget when unlinked and the username when linked' do
      sign_in admin

      get '/admin/my_account'
      expect(response.body).to include('telegram-widget.js')
      # Arbre's render both inserts and returns a partial — each icon must
      # appear exactly once (the fills identify the logo and done-icon SVGs).
      expect(response.body.scan('#2AABEE').count).to eq(1)

      admin.update!(telegram_id: 42, telegram_username: 'kyryl')
      get '/admin/my_account'
      expect(response.body).to include('@kyryl')
      expect(response.body.scan('#2AABEE').count).to eq(1)
      expect(response.body.scan('text-green-500').count).to eq(1)
    end

    it 'embeds the column picker on My Account and saves back to it' do
      sign_in admin

      get '/admin/my_account'
      expect(response.body).to include('visible_columns')

      patch '/admin/table_columns/update',
            params: { resource_key: 'products', visible_columns: [ '', 'name' ] },
            headers: { 'HTTP_REFERER' => 'http://www.example.com/admin/my_account' }

      expect(response).to redirect_to('/admin/my_account')
      expect(admin.table_preferences.find_by(resource_key: 'products').visible_columns).to eq([ 'name' ])
    end

    it 'disconnects Telegram from My Account, keeping password login intact' do
      admin.update!(telegram_id: 42, telegram_username: 'kyryl')
      sign_in admin

      delete '/admin/my_account/disconnect_telegram'

      expect(admin.reload.telegram_id).to be_nil
      expect(admin.telegram_username).to be_nil

      sign_out admin
      post '/admin/login', params: { admin: { email: admin.email, password: password } }
      expect(warden_admin_id).to eq(admin.id)
    end
  end
end
