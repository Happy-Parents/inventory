module ConfigurableColumns
  # The columns declared for one ActiveAdmin resource, in declaration order.
  class Registry
    attr_reader :resource_key, :columns

    def self.build(resource_key, &block)
      builder = Builder.new
      builder.instance_eval(&block)
      new(resource_key, builder.columns)
    end

    def initialize(resource_key, columns)
      @resource_key = resource_key.to_s
      @columns = columns.freeze
    end

    def keys = columns.map(&:key)

    def default_keys = columns.select(&:default?).map(&:key)

    # Declared columns matching the given keys, in declaration order. Unknown or
    # stale keys are dropped; a blank selection falls back to the defaults, so an
    # admin can never end up with an empty table.
    def columns_for(keys)
      wanted = Array(keys).map(&:to_sym)
      wanted = default_keys if (wanted & self.keys).empty?

      columns.select { |column| wanted.include?(column.key) }
    end

    def selected_keys(keys) = columns_for(keys).map(&:key)

    # Collects `column` declarations from a `configurable_columns` block.
    class Builder
      attr_reader :columns

      def initialize
        @columns = []
      end

      def column(key, **options, &block)
        @columns << Column.new(key, block: block, **options)
      end
    end
  end
end
