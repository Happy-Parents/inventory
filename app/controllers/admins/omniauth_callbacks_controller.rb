module Admins
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2 = sign_in_with_email
    def github        = sign_in_with_email
    def telegram      = admin_signed_in? ? connect_telegram : sign_in_with_telegram
    def failure       = handle_omniauth_sign_failure

    private

    def sign_in_with_email
      sign_in_result = ResolveAdminByEmail.call(omniauth_hash)
      sign_in_and_redirect sign_in_result.admin, event: :authentication

      rescue ActiveRecord::RecordNotFound
        open_sign_in(alert: t('devise.omniauth_callbacks.not_authorized'))
    end

    def connect_telegram
      ConnectTelegram.call(current_admin, omniauth_hash)
      open_my_account(notice: t('devise.omniauth_callbacks.telegram_linked'))

    rescue ActiveRecord::RecordNotUnique
      open_my_account(alert: t('devise.omniauth_callbacks.telegram_taken'))
    end

    def sign_in_with_telegram
      sign_in_result = ResolveAdminByTelegram.call(omniauth_hash)
      sign_in_and_redirect sign_in_result.admin, event: :authentication

      rescue ActiveRecord::RecordNotFound
        open_sign_in(alert: t('devise.omniauth_callbacks.telegram_not_linked'))
    end

    def open_sign_in(notification)
      redirect_to new_admin_session_path, notification
    end

    def open_my_account(notification)
      redirect_to admin_my_account_path, notification
    end

    def handle_omniauth_sign_failure
      redirect_to new_admin_session_path,
                  alert: t('devise.omniauth_callbacks.failure',
                           kind: OmniAuth::Utils.camelize(failed_strategy.name),
                           reason: failure_message)
    end

    def omniauth_hash = request.env['omniauth.auth']
  end
end
