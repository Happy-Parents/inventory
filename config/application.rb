require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

module Inventory
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = 'Europe/Kyiv'
    config.i18n.available_locales = [ :uk, :en ]
    config.i18n.default_locale = :uk
    config.i18n.fallbacks = [ :en ]

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
