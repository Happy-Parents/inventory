Rails.application.routes.draw do
  root to: redirect('/admin')

  devise_for :admins, ActiveAdmin::Devise.config.deep_merge(
    controllers: { omniauth_callbacks: 'admins/omniauth_callbacks' }
  )

  ActiveAdmin.routes(self)

  get 'robots.txt' => 'robots#show', as: :robots, format: false
  get 'up' => 'rails/health#show', as: :rails_health_check
end
