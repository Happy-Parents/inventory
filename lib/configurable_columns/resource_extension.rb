module ConfigurableColumns
  # Mixed into ActiveAdmin::Resource so every registered resource can carry the
  # registry declared for it. Resources are rebuilt whenever app/admin is
  # reloaded, so the registry never outlives the code that declared it.
  module ResourceExtension
    attr_accessor :column_registry

    def configurable_columns? = column_registry.present?
  end
end
