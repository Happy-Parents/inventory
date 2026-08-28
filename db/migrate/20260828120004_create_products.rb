class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :manufacturer_name, null: false
      t.string :name
      t.string :manufacturer_sku
      t.string :sku
      t.references :brand, foreign_key: true
      t.references :category, foreign_key: true
      t.string :language, null: false, default: "unknown"
      t.string :site_status, null: false, default: "needs_review"
      t.string :packaging_condition, null: false, default: "ok"
      t.string :hp_url
      t.text :notes

      t.timestamps
    end

    add_index :products, :manufacturer_sku
    add_index :products, :sku
  end
end
