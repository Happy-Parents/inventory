Rails.application.routes.draw do
  root to: redirect('/admin')

  devise_for :admins, ActiveAdmin::Devise.config.deep_merge(
    controllers: { omniauth_callbacks: 'admins/omniauth_callbacks' }
  )

  ActiveAdmin.routes(self)

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :session, only: %i[create destroy] do
        post :refresh
      end
      get 'me', to: 'me#show'
    end
  end

  mount Rswag::Api::Engine => '/api'
  mount Rswag::Ui::Engine => '/api/v1/docs'

  get 'robots.txt' => 'robots#show', as: :robots, format: false
  get 'up' => 'rails/health#show', as: :rails_health_check
end
