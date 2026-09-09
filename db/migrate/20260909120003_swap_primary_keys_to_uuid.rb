class SwapPrimaryKeysToUuid < ActiveRecord::Migration[8.1]
  TABLES = %w[admins brands categories warehouses products stock_items].freeze

  def up
    # 1. Release every foreign key so the bigint primary keys can be dropped.
    remove_foreign_key :categories,  :categories, column: :parent_id
    remove_foreign_key :products,    :brands
    remove_foreign_key :products,    :categories
    remove_foreign_key :stock_items, :products
    remove_foreign_key :stock_items, :warehouses

    # 2. Promote uuid to primary key; demote id to legacy_id.
    TABLES.each { |table| promote_uuid_pk(table) }

    # 3. Point the association columns at the new keys.
    swap_fk :categories,  :parent
    swap_fk :products,    :brand
    swap_fk :products,    :category
    swap_fk :stock_items, :product
    swap_fk :stock_items, :warehouse

    # 4. Rebuild the indexes that went away with the dropped columns.
    add_index :categories,  :parent_id
    add_index :products,    :brand_id
    add_index :products,    :category_id
    add_index :stock_items, :product_id
    add_index :stock_items, :warehouse_id
    add_index :stock_items, %i[product_id warehouse_id], unique: true

    # 5. Restore referential integrity.
    add_foreign_key :categories,  :categories, column: :parent_id
    add_foreign_key :products,    :brands
    add_foreign_key :products,    :categories
    add_foreign_key :stock_items, :products
    add_foreign_key :stock_items, :warehouses

    # 6. active_admin_comments is empty and polymorphic - rebuild it outright.
    drop_table :active_admin_comments
    create_table :active_admin_comments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :namespace
      t.text   :body
      t.references :resource, polymorphic: true, type: :uuid
      t.references :author,   polymorphic: true, type: :uuid
      t.timestamps
    end
    add_index :active_admin_comments, :namespace
  end

  # A partial un-swap is worse than a restore: roll back with pg_restore instead.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def promote_uuid_pk(table)
    execute <<~SQL
      ALTER TABLE #{table} DROP CONSTRAINT #{table}_pkey;
      ALTER TABLE #{table} ALTER COLUMN id DROP DEFAULT;
      ALTER TABLE #{table} RENAME COLUMN id TO legacy_id;
      ALTER TABLE #{table} ALTER COLUMN legacy_id DROP NOT NULL;
      ALTER TABLE #{table} RENAME COLUMN uuid TO id;
      ALTER TABLE #{table}
        ADD CONSTRAINT #{table}_pkey PRIMARY KEY USING INDEX index_#{table}_on_uuid;
      ALTER TABLE #{table} ALTER COLUMN id SET DEFAULT gen_random_uuid();
    SQL
  end

  def swap_fk(table, assoc)
    remove_column table, :"#{assoc}_id"
    rename_column table, :"#{assoc}_uuid", :"#{assoc}_id"
  end
end
