class DropLegacyIds < ActiveRecord::Migration[8.1]
  TABLES = %i[admins brands categories warehouses products stock_items].freeze

  def up
    # Dropping each column also drops the bigint sequence it still owns.
    TABLES.each { |table| remove_column table, :legacy_id }
  end

  # The column can be recreated, but the old bigint values are gone for good.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
