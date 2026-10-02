class AddTelegramToAdmins < ActiveRecord::Migration[8.1]
  def change
    add_column :admins, :telegram_id, :bigint
    add_column :admins, :telegram_username, :string
    add_index :admins, :telegram_id, unique: true
  end
end
