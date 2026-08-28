class CreateWarehouses < ActiveRecord::Migration[8.1]
  def change
    create_table :warehouses do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :warehouses, :name, unique: true
  end
end
