# This migration comes from activeadmin_configurable_columns (originally 20261026000001)
class AddColumnOrderToActiveadminConfigurableColumnsPreferences < ActiveRecord::Migration[7.1]
  def change
    # JSON-serialized array of every declared column key, in the admin's order.
    # NULL for selections saved before reordering existed: declaration order.
    add_column :activeadmin_configurable_columns_preferences, :column_order, :text
  end
end
