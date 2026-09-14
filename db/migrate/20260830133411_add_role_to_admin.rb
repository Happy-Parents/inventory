class AddRoleToAdmin < ActiveRecord::Migration[8.1]
  def change
    add_column :admins, :role, :string, null: false, default: 'manager'
  end
end
