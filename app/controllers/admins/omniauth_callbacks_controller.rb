module Admins
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # Google redirects here after authentication. The admins table is the
    # whitelist: only an email with an existing Admin row may sign in.
    def google_oauth2
      email = request.env['omniauth.auth'].info.email.to_s.downcase
      admin = Admin.find_by(email: email)

      if admin
        sign_in_and_redirect admin, event: :authentication
      else
        redirect_to new_admin_session_path,
                    alert: t('devise.omniauth_callbacks.not_authorized', email: email)
      end
    end

    def failure
      redirect_to new_admin_session_path,
                  alert: t('devise.omniauth_callbacks.failure',
                           kind: 'Google', reason: failure_message)
    end
  end
end
