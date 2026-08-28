class CreateStockItems < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_items do |t|
      t.references :product, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 0
      t.integer :damaged_quantity, null: false, default: 0

      t.timestamps
    end

    add_index :stock_items, [ :product_id, :warehouse_id ], unique: true
  end
end
