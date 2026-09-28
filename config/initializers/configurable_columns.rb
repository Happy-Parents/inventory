# Teaches ActiveAdmin the `configurable_columns` DSL -- see
# lib/configurable_columns.rb. Runs after config/initializers/active_admin.rb
# (alphabetical order) and before ActiveAdmin loads app/admin, which is where
# the DSL gets called.
require Rails.root.join('lib/configurable_columns').to_s

ActiveAdmin::Resource.include ConfigurableColumns::ResourceExtension
ActiveAdmin::ResourceDSL.include ConfigurableColumns::Dsl
ActiveAdmin::Views::IndexAsTable::IndexTableFor.include ConfigurableColumns::TableRenderer
