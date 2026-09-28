module ConfigurableColumns
  # Mixed into ActiveAdmin::Views::IndexAsTable::IndexTableFor, so that
  # `configurable_columns` inside an `index` block renders the columns the
  # current admin chose (falling back to the declared defaults).
  module TableRenderer
    def configurable_columns
      registry = active_admin_config.column_registry

      if registry.nil?
        raise ConfigurableColumns::NotDeclared, active_admin_config.resource_name.to_s
      end

      ConfigurableColumns
        .visible_columns(registry, helpers.current_active_admin_user)
        .each { |column| column.render_into(self) }
    end
  end
end
