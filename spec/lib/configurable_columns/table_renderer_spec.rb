RSpec.describe ConfigurableColumns::TableRenderer do
  let(:admin) { :admin_alice }
  let(:helpers) { ConfigurableColumnsFakes::Helpers.new(admin) }
  let(:config) { ConfigurableColumnsFakes::ResourceConfig.new(route_key: 'widgets') }
  let(:table) do
    Class.new(ConfigurableColumnsFakes::Table) { include ConfigurableColumns::TableRenderer }
      .new(config: config, helpers: helpers)
  end

  before do
    config.column_registry = ConfigurableColumns::Registry.build('widgets') do
      column :name
      column :code
      column :notes, default: false
    end
  end

  it 'renders the declared defaults when the admin never saved anything' do
    ConfigurableColumns.preference_store = ConfigurableColumnsFakes::Store.new

    table.configurable_columns

    expect(table.titles).to eq(%i[name code])
  end

  it 'renders the columns the current admin saved' do
    ConfigurableColumns.preference_store =
      ConfigurableColumnsFakes::Store.new(admin => { 'widgets' => %i[notes name] })

    table.configurable_columns

    expect(table.titles).to eq(%i[name notes])
  end

  it 'ignores what other admins saved' do
    ConfigurableColumns.preference_store =
      ConfigurableColumnsFakes::Store.new(admin_bob: { 'widgets' => %i[notes] })

    table.configurable_columns

    expect(table.titles).to eq(%i[name code])
  end

  it 'explains itself when the resource never declared its columns' do
    config.column_registry = nil

    expect { table.configurable_columns }
      .to raise_error(ConfigurableColumns::NotDeclared, /widgets.*configurable_columns do/m)
  end
end
