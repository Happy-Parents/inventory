class AddUuidColumns < ActiveRecord::Migration[8.1]
  TABLES = %i[admins brands categories warehouses products stock_items].freeze

  def change
    TABLES.each do |table|
      add_column table, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false
      add_index  table, :uuid, unique: true
    end

    # Shadow columns for every foreign key, backfilled by the next migration.
    add_column :categories,  :parent_uuid,    :uuid
    add_column :products,    :brand_uuid,     :uuid
    add_column :products,    :category_uuid,  :uuid
    add_column :stock_items, :product_uuid,   :uuid
    add_column :stock_items, :warehouse_uuid, :uuid
  end
end
