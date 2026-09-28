module ConfigurableColumns
  # A single column an admin may show or hide. Mirrors the arguments of
  # ActiveAdmin's `column` so a declaration reads the same as the index DSL it
  # replaces.
  class Column
    attr_reader :key, :attribute, :label, :options, :block

    def initialize(key, label: nil, default: true, attribute: nil, block: nil, **options)
      @key = key.to_sym
      @attribute = (attribute || key).to_sym
      @label = label
      @default = default
      @options = options
      @block = block
    end

    def default? = @default

    # Emits the column into an ActiveAdmin index table.
    def render_into(table)
      args = []
      args << label if label
      args << attribute unless label && block
      args << options

      table.column(*args, &cell_renderer(table))
    end

    # ActiveAdmin renders a column block with a plain `block.call(resource)`
    # (DisplayHelper#find_value), so the block runs with whatever `self` it captured
    # where it was written. Written inside an `index` block that is the view, which is
    # how view helpers resolve. Ours is written inside a `configurable_columns` block,
    # evaluated against the Builder, so it has to be rebound to the table at render
    # time -- otherwise a helper call in a column block raises NoMethodError.
    def cell_renderer(table)
      return nil unless block

      proc { |resource| table.instance_exec(resource, &block) }
    end

    # Human name for the checkbox in the settings form.
    def human_label(resource_class)
      return label if label
      return attribute.to_s.humanize unless resource_class.respond_to?(:human_attribute_name)

      resource_class.human_attribute_name(attribute, default: attribute.to_s.humanize)
    end
  end
end
