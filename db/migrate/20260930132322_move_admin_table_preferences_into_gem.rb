# Saved column selections predate the activeadmin_configurable_columns gem and
# lived in the app's own admin_table_preferences table. Move them into the
# gem's table (polymorphic admin, string id, JSON text) and drop the old one.
class MoveAdminTablePreferencesIntoGem < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO activeadmin_configurable_columns_preferences
        (admin_type, admin_id, resource_key, visible_columns, created_at, updated_at)
      SELECT 'Admin', admin_id::text, resource_key, visible_columns::text, created_at, updated_at
      FROM admin_table_preferences
    SQL

    drop_table :admin_table_preferences
  end

  def down
    create_table :admin_table_preferences, id: :uuid do |t|
      t.references :admin, type: :uuid, null: false, foreign_key: true
      t.string :resource_key, null: false
      t.jsonb :visible_columns, null: false, default: []
      t.timestamps
    end

    add_index :admin_table_preferences, [ :admin_id, :resource_key ], unique: true

    execute <<~SQL
      INSERT INTO admin_table_preferences
        (id, admin_id, resource_key, visible_columns, created_at, updated_at)
      SELECT gen_random_uuid(), admin_id::uuid, resource_key, visible_columns::jsonb, created_at, updated_at
      FROM activeadmin_configurable_columns_preferences
      WHERE admin_type = 'Admin'
    SQL

    execute "DELETE FROM activeadmin_configurable_columns_preferences WHERE admin_type = 'Admin'"
  end
end
