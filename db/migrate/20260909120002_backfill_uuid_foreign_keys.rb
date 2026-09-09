class BackfillUuidForeignKeys < ActiveRecord::Migration[8.1]
  PAIRS = [
    %w[categories parent],
    %w[products brand],
    %w[products category],
    %w[stock_items product],
    %w[stock_items warehouse]
  ].freeze

  def up
    execute <<~SQL
      UPDATE categories  c SET parent_uuid    = p.uuid FROM categories p WHERE c.parent_id    = p.id;
      UPDATE products    p SET brand_uuid     = b.uuid FROM brands     b WHERE p.brand_id     = b.id;
      UPDATE products    p SET category_uuid  = c.uuid FROM categories c WHERE p.category_id  = c.id;
      UPDATE stock_items s SET product_uuid   = p.uuid FROM products   p WHERE s.product_id   = p.id;
      UPDATE stock_items s SET warehouse_uuid = w.uuid FROM warehouses w WHERE s.warehouse_id = w.id;
    SQL

    # A dangling pointer here would silently drop an association during the swap.
    PAIRS.each do |table, assoc|
      dangling = select_value(<<~SQL).to_i
        SELECT count(*) FROM #{table}
        WHERE #{assoc}_id IS NOT NULL AND #{assoc}_uuid IS NULL
      SQL
      raise "#{dangling} rows in #{table} have a dangling #{assoc}_id" if dangling.positive?
    end

    # stock_items.product_id / warehouse_id are NOT NULL - the replacements must be too.
    change_column_null :stock_items, :product_uuid,   false
    change_column_null :stock_items, :warehouse_uuid, false
  end

  def down
    change_column_null :stock_items, :product_uuid,   true
    change_column_null :stock_items, :warehouse_uuid, true

    execute <<~SQL
      UPDATE categories  SET parent_uuid    = NULL;
      UPDATE products    SET brand_uuid     = NULL, category_uuid = NULL;
      UPDATE stock_items SET product_uuid   = NULL, warehouse_uuid = NULL;
    SQL
  end
end
