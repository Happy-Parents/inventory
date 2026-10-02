module Admins
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # Providers redirect here after authentication. The admins table is the
    # whitelist: only an email with an existing Admin row may sign in.
    def google_oauth2 = whitelist_sign_in
    def github        = whitelist_sign_in

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
  end
end
