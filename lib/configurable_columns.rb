# Per-admin index table columns for ActiveAdmin.
#
# ActiveAdmin has no built-in way to let each admin choose which columns of an
# index table they see (and the one gem that does, activeadmin_dynamic_table,
# supports ActiveAdmin < 4.0 and keeps the choice in the URL). This is the
# in-house equivalent, built on ActiveAdmin's own extension points:
#
#   * ResourceDSL  -- `configurable_columns` declares the available columns
#   * IndexTableFor -- `configurable_columns` renders the chosen ones
#   * SidebarSection -- the picker next to every configurable index table
#
# The choice is stored per admin in AdminTablePreference.
# This file is deliberately outside the autoload paths (see
# config/application.rb): its modules are included into ActiveAdmin classes that
# are never reloaded, so they must not be reloadable themselves.
module ConfigurableColumns
  # Rendered right below the filters sidebar section, which uses priority 10.
  SIDEBAR_PRIORITY = 20

  # Raised when an index renders `configurable_columns` without a matching
  # `configurable_columns do ... end` declaration.
  class NotDeclared < StandardError
    def initialize(resource_name)
      super("#{resource_name} renders configurable_columns but never declares them. " \
            'Add a `configurable_columns do ... end` block to its ActiveAdmin registration.')
    end
  end

  class << self
    # Where saved selections come from. Any object answering
    #
    #   visible_column_keys(admin, resource_key) -> [Symbol] | nil   (nil = never saved)
    #
    # can be plugged in; the application defaults to AdminTablePreference. Assigning
    # nil restores that default, which is how specs hand back the real store.
    attr_writer :preference_store

    def preference_store = @preference_store || AdminTablePreference

    # The columns the given admin sees for this resource.
    def visible_columns(registry, admin)
      saved = preference_store.visible_column_keys(admin, registry.resource_key)

      registry.columns_for(saved || registry.default_keys)
    end

    # Every resource of the namespace that declares configurable columns.
    def resources(namespace)
      namespace.resources.select do |resource|
        resource.respond_to?(:configurable_columns?) && resource.configurable_columns?
      end
    end

    def resource_for(namespace, resource_key)
      resources(namespace).find { |resource| resource.column_registry.resource_key == resource_key.to_s }
    end
  end
end

require_relative 'configurable_columns/column'
require_relative 'configurable_columns/registry'
require_relative 'configurable_columns/dsl'
require_relative 'configurable_columns/resource_extension'
require_relative 'configurable_columns/table_renderer'
