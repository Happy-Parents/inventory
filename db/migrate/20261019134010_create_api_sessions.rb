class CreateApiSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :api_sessions, id: :uuid do |t|
      t.references :admin, null: false, foreign_key: true, type: :uuid
      t.string :refresh_token_digest, null: false
      t.string :provider, null: false
      t.string :device_name
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :api_sessions, :refresh_token_digest, unique: true
  end
end
