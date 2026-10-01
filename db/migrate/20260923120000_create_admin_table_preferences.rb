class CreateAdminTablePreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_table_preferences, id: :uuid do |t|
      t.references :admin, type: :uuid, null: false, foreign_key: true
      t.string :resource_key, null: false
      t.jsonb :visible_columns, null: false, default: []
      t.timestamps
    end

    add_index :admin_table_preferences, [ :admin_id, :resource_key ], unique: true
  end
end
