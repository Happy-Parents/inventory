# A throwaway ActiveAdmin resource, registered only in the test environment, so the
# configurable_columns library can be exercised against a real ActiveAdmin
# registration without any of the application's own tables taking part.
class ConfigurableColumnsDummy < ApplicationRecord
  self.table_name = 'configurable_columns_dummies'

  def self.ransackable_attributes(_auth_object = nil) = column_names
  def self.ransackable_associations(_auth_object = nil) = []
end

# ActiveAdmin loads lazily: until it has, ActiveAdmin::Resource is missing the
# extensions (batch actions, filters) that its initializer relies on, and a resource
# registered before that point renders broken. Force the load first.
ActiveAdmin.application.load!

ActiveAdmin.register ConfigurableColumnsDummy do
  menu false

  configurable_columns do
    column :title
    # Calls a view helper with an implicit receiver, which only resolves when the
    # block is executed against the rendering table.
    column(:linked) { |dummy| link_to dummy.title, '#' }
    column :code, default: false
  end

  index do
    selectable_column
    configurable_columns
    actions
  end
end

Rails.application.reload_routes!

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.connection.create_table :configurable_columns_dummies, if_not_exists: true do |t|
      t.string :title
      t.string :code
      t.timestamps
    end
  end
end
