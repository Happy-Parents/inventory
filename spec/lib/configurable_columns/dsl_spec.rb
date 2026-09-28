RSpec.describe ConfigurableColumns::Dsl do
  let(:config) { ConfigurableColumnsFakes::ResourceConfig.new(route_key: 'widgets') }
  let(:dsl) { ConfigurableColumnsFakes::ResourceDsl.new(config) }

  describe '#configurable_columns' do
    before do
      dsl.configurable_columns do
        column :name
        column :notes, default: false
      end
    end

    it 'stores a registry on the resource' do
      expect(config.column_registry).to be_a(ConfigurableColumns::Registry)
      expect(config.column_registry.keys).to eq(%i[name notes])
    end

    it 'keys the registry by the resource route key' do
      expect(config.column_registry.resource_key).to eq('widgets')
    end

    it 'adds exactly one sidebar section' do
      expect(config.sidebar_sections.size).to eq(1)
    end

    describe 'the sidebar section' do
      subject(:section) { config.sidebar_sections.first }

      it 'is named for the columns picker' do
        expect(section.name).to eq('columns')
      end

      it 'is shown on the index only' do
        expect(section.display_on?('index')).to be(true)
        expect(section.display_on?('show')).to be(false)
      end

      it 'sits below the filters section, which ActiveAdmin gives priority 10' do
        expect(section.priority).to eq(ConfigurableColumns::SIDEBAR_PRIORITY)
        expect(section.priority).to be > 10
      end

      it 'renders the picker for its own resource' do
        view = ConfigurableColumnsFakes::SidebarView.new(config)

        view.instance_exec(&section.block)

        expect(view.rendered).to eq([ 'admin/table_columns/sidebar', { resource: config } ])
      end
    end
  end
end
