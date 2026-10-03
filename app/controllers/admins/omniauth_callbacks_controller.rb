module Admins
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # Providers redirect here after authentication.
    # The admins table is the whitelist: only an email with an existing Admin row may sign in.
    def google_oauth2 = whitelist_sign_in
    def github        = whitelist_sign_in

    # Telegram shares no email, so the whitelist is the explicit link instead:
    # a signed-in admin's click stores their telegram_id; a signed-out click
    # only matches an already-linked admin. No auto-provisioning either way.
    def telegram
      auth = request.env['omniauth.auth']
      admin_signed_in? ? link_telegram(auth) : telegram_sign_in(auth)
    end

    def failure
      redirect_to new_admin_session_path,
                  alert: t('devise.omniauth_callbacks.failure',
                           kind: OmniAuth::Utils.camelize(failed_strategy.name),
                           reason: failure_message)
    end

    private

    def whitelist_sign_in
      email = request.env['omniauth.auth'].info.email.to_s.downcase
      admin = Admin.find_by(email: email)

      if admin
        sign_in_and_redirect admin, event: :authentication
      else
        redirect_to new_admin_session_path,
                    alert: t('devise.omniauth_callbacks.not_authorized', email: email)
      end
    end

    def link_telegram(auth)
      current_admin.update!(telegram_id: auth.uid,
                            telegram_username: auth.info.nickname)
      redirect_to admin_root_path,
                  notice: t('devise.omniauth_callbacks.telegram_linked')
    rescue ActiveRecord::RecordNotUnique
      redirect_to admin_root_path,
                  alert: t('devise.omniauth_callbacks.telegram_taken')
    end

    def telegram_sign_in(auth)
      admin = Admin.find_by(telegram_id: auth.uid)

      if admin
        admin.update(telegram_username: auth.info.nickname) # keep display fresh
        sign_in_and_redirect admin, event: :authentication
      else
        redirect_to new_admin_session_path,
                    alert: t('devise.omniauth_callbacks.telegram_not_linked')
      end
    end
  end
end
