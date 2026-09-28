RSpec.describe ConfigurableColumns do
  let(:registry) do
    ConfigurableColumns::Registry.build('widgets') do
      column :name
      column :code
      column :notes, default: false
    end
  end

  describe '.preference_store' do
    it 'defaults to a store that answers the read contract' do
      expect(described_class.preference_store).to respond_to(:visible_column_keys)
    end

    it 'can be replaced' do
      store = ConfigurableColumnsFakes::Store.new

      described_class.preference_store = store

      expect(described_class.preference_store).to eq(store)
    end

    it 'falls back to the default store when cleared' do
      default = described_class.preference_store
      described_class.preference_store = ConfigurableColumnsFakes::Store.new

      described_class.preference_store = nil

      expect(described_class.preference_store).to eq(default)
    end
  end

  describe '.visible_columns' do
    it 'returns the declared defaults when the admin never saved anything' do
      described_class.preference_store = ConfigurableColumnsFakes::Store.new

      expect(described_class.visible_columns(registry, :alice).map(&:key)).to eq(%i[name code])
    end

    it 'returns what the admin saved' do
      described_class.preference_store =
        ConfigurableColumnsFakes::Store.new(alice: { 'widgets' => %i[notes] })

      expect(described_class.visible_columns(registry, :alice).map(&:key)).to eq(%i[notes])
    end

    it 'asks the store for this resource and this admin' do
      store = ConfigurableColumnsFakes::Store.new
      allow(store).to receive(:visible_column_keys).and_return(nil)
      described_class.preference_store = store

      described_class.visible_columns(registry, :alice)

      expect(store).to have_received(:visible_column_keys).with(:alice, 'widgets')
    end
  end

  describe '.resources' do
    let(:configured) do
      ConfigurableColumnsFakes::ResourceConfig.new(route_key: 'widgets')
        .tap { |config| config.column_registry = registry }
    end
    let(:undeclared) { ConfigurableColumnsFakes::ResourceConfig.new(route_key: 'gadgets') }
    # ActiveAdmin pages sit in the same collection and answer none of this.
    let(:page) { Object.new }

    it 'keeps only resources that declared columns' do
      namespace = ConfigurableColumnsFakes::Namespace.new([ page, undeclared, configured ])

      expect(described_class.resources(namespace)).to eq([ configured ])
    end

    it 'is empty when nothing is configurable' do
      namespace = ConfigurableColumnsFakes::Namespace.new([ page, undeclared ])

      expect(described_class.resources(namespace)).to be_empty
    end

    describe '.resource_for' do
      let(:namespace) { ConfigurableColumnsFakes::Namespace.new([ page, undeclared, configured ]) }

      it 'finds a configurable resource by its key' do
        expect(described_class.resource_for(namespace, 'widgets')).to eq(configured)
      end

      it 'accepts a symbol key' do
        expect(described_class.resource_for(namespace, :widgets)).to eq(configured)
      end

      it 'returns nil for an unknown key' do
        expect(described_class.resource_for(namespace, 'made_up')).to be_nil
      end

      it 'returns nil for a resource that declared no columns' do
        expect(described_class.resource_for(namespace, 'gadgets')).to be_nil
      end
    end
  end

  describe ConfigurableColumns::NotDeclared do
    it 'names the resource and the missing declaration' do
      expect(described_class.new('Widget').message)
        .to eq('Widget renders configurable_columns but never declares them. ' \
               'Add a `configurable_columns do ... end` block to its ActiveAdmin registration.')
    end
  end
end
