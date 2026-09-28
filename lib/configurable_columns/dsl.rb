module ConfigurableColumns
  # Mixed into ActiveAdmin::ResourceDSL. Declares the columns an admin may pick
  # from, and adds the "Columns" sidebar section to the index page:
  #
  #   ActiveAdmin.register Product do
  #     configurable_columns do
  #       column :brand
  #       column :qty, sortable: 'stock_items_quantity' { |p| p.total_quantity }
  #       column :notes, default: false
  #     end
  #
  #     index do
  #       selectable_column
  #       configurable_columns
  #       actions
  #     end
  #   end
  module Dsl
    def configurable_columns(&block)
      config.column_registry = Registry.build(config.resource_name.route_key, &block)
      config.sidebar_sections << columns_sidebar_section
    end

    private

    def columns_sidebar_section
      ActiveAdmin::SidebarSection.new(
        :columns,
        only: :index,
        priority: ConfigurableColumns::SIDEBAR_PRIORITY
      ) do
        render 'admin/table_columns/sidebar', resource: active_admin_config
      end
    end
  end
end
