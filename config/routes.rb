Rails.application.routes.draw do
  root to: redirect('/admin')

  devise_for :admins, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  get "up" => "rails/health#show", as: :rails_health_check
end
