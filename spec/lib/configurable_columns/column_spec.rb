RSpec.describe ConfigurableColumns::Column do
  let(:table) { ConfigurableColumnsFakes::Table.new }

  describe 'defaults' do
    it 'derives the attribute from the key' do
      column = described_class.new(:title)

      expect(column.key).to eq(:title)
      expect(column.attribute).to eq(:title)
    end

    it 'accepts string keys' do
      expect(described_class.new('title').key).to eq(:title)
    end

    it 'accepts an attribute that differs from the key' do
      column = described_class.new(:qty, attribute: :total_quantity)

      expect(column.key).to eq(:qty)
      expect(column.attribute).to eq(:total_quantity)
    end

    it 'is visible by default' do
      expect(described_class.new(:title)).to be_default
    end

    it 'can be declared hidden by default' do
      expect(described_class.new(:title, default: false)).not_to be_default
    end

    it 'keeps unknown options for ActiveAdmin' do
      expect(described_class.new(:title, sortable: 'other', class: 'x').options)
        .to eq(sortable: 'other', class: 'x')
    end
  end

  describe '#render_into' do
    it 'emits the attribute for a plain column' do
      described_class.new(:title).render_into(table)

      expect(table.emitted.first.args).to eq([ :title, {} ])
      expect(table.emitted.first.block).to be_nil
    end

    it 'emits the attribute and a renderer for a block column' do
      described_class.new(:title, block: proc { 'x' }).render_into(table)

      expect(table.emitted.first.args).to eq([ :title, {} ])
      expect(table.emitted.first.block).to be_a(Proc)
    end

    it 'emits label and attribute when a label is given without a block' do
      described_class.new(:sku, label: 'SKU').render_into(table)

      expect(table.emitted.first.args).to eq([ 'SKU', :sku, {} ])
    end

    it 'emits only the label when a label comes with a block' do
      described_class.new(:sku, label: 'SKU', block: proc { 'x' }).render_into(table)

      expect(table.emitted.first.args).to eq([ 'SKU', {} ])
    end

    it 'passes the remaining options through as the last argument' do
      described_class.new(:title, sortable: 'other').render_into(table)

      expect(table.options.first).to eq(sortable: 'other')
    end
  end

  describe 'the emitted renderer' do
    # ActiveAdmin calls a column block with a bare `block.call(resource)`, so the block
    # keeps whatever `self` it was written under -- here the declaration Builder, which
    # knows no view helpers. The renderer has to rebind it to the table.
    it 'runs the block against the table, not the declaring context' do
      registry = ConfigurableColumns::Registry.build('widgets') do
        column(:loud) { |widget| shout(widget) }
      end

      registry.columns.first.render_into(table)

      expect(table.emitted.first.block.call('hi')).to eq('shout:hi')
    end

    it 'passes the resource to the block' do
      described_class.new(:title, block: proc { |widget| widget.upcase }).render_into(table)

      expect(table.emitted.first.block.call('hi')).to eq('HI')
    end
  end

  describe '#human_label' do
    it 'prefers an explicit label' do
      expect(described_class.new(:sku, label: 'SKU').human_label(ConfigurableColumnsFakes::TranslatedModel))
        .to eq('SKU')
    end

    it 'asks the model for a translated attribute name' do
      expect(described_class.new(:title).human_label(ConfigurableColumnsFakes::TranslatedModel))
        .to eq('translated:title')
    end

    it 'uses the attribute rather than the key when they differ' do
      expect(described_class.new(:qty, attribute: :total).human_label(ConfigurableColumnsFakes::TranslatedModel))
        .to eq('translated:total')
    end

    it 'humanizes the attribute when the class cannot translate' do
      expect(described_class.new(:total_quantity).human_label(Class.new)).to eq('Total quantity')
    end
  end
end
