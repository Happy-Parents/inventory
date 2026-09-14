source "https://rubygems.org"

# Core
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
gem "pg", ">= 1.6.3"
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# Application
gem "csv"
gem "rails-i18n"
gem "bcrypt", "~> 3.1.7"
gem "activeadmin", "4.0.0.beta22"
gem "devise", ">= 5.0.4"
gem 'pundit', '>= 2.5.2'

# Assets
gem 'propshaft', '>= 1.3.2'
gem 'importmap-rails', '>= 2.2.3'
gem 'turbo-rails', '>= 2.0.23'
gem 'stimulus-rails', '>= 1.3.4'
gem "tailwindcss-ruby", "~> 4.0"
gem 'solid_cache', '>= 1.0.10'
gem 'solid_queue', '>= 1.7'


# Server Provisioning
gem 'kamal', '>= 2.12', require: false
gem 'thruster', '>= 0.1.26', require: false
gem "image_processing", "~> 1.2"

group :development, :test do
  gem 'bullet', '>= 8.2'
  gem 'ffaker', '>= 2.25'
  gem 'awesome_print', '>= 1.9.2'
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem 'factory_bot_rails', '>= 6.5.1'
end

group :test do
  gem 'rspec-rails', '>= 8.0.4'
  gem 'shoulda-matchers', '>= 8.0.1'
  gem 'pundit-matchers', '>= 4.0'
end
group :development do
  gem "tzinfo-data", platforms: %i[ windows jruby ]
end
