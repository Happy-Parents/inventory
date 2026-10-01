# This migration comes from activeadmin_configurable_columns (originally 20260930000001)
class CreateActiveadminConfigurableColumnsPreferences < ActiveRecord::Migration[7.1]
  def change
    create_table :activeadmin_configurable_columns_preferences do |t|
      # A string id fits every primary key type a current-user model may have.
      t.string :admin_type, null: false
      t.string :admin_id, null: false
      t.string :resource_key, null: false
      # JSON-serialized array of column keys; plain text so every adapter works.
      t.text :visible_columns
      t.timestamps
    end

    add_index :activeadmin_configurable_columns_preferences,
              %i[admin_type admin_id resource_key],
              unique: true,
              name: 'index_aacc_preferences_on_admin_and_resource_key'
  end
end
