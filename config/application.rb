require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

module Inventory
  class Application < Rails::Application
    config.load_defaults 8.1

    # configurable_columns is required explicitly from its initializer: it is
    # mixed into ActiveAdmin classes that are never reloaded, so it must not be
    # reloadable itself.
    config.autoload_lib(ignore: %w[assets tasks configurable_columns configurable_columns.rb])

    config.time_zone = 'Kyiv'
    config.i18n.available_locales = [ :uk, :en ]
    config.i18n.default_locale = :uk
    config.i18n.fallbacks = [ :en ]

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
