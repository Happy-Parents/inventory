# End-to-end coverage of the configurable_columns library inside a real ActiveAdmin
# registration. It runs against the throwaway resource in
# spec/support/configurable_columns_dummy.rb, so none of the application's own tables
# take part and converting or removing them cannot break these expectations.
RSpec.describe 'Configurable table columns' do
  let(:admin) { create(:admin) }
  let(:resource_key) { 'configurable_columns_dummies' }
  let(:resource) { ConfigurableColumns.resource_for(ActiveAdmin.application.namespaces[:admin], resource_key) }
  let(:registry) { resource.column_registry }

  # ActiveAdmin stamps every table header and cell with the column it renders.
  def rendered_columns = response.body.scan(/data-column="([^"]+)"/).flatten.uniq.map(&:to_sym)

  before do
    sign_in admin
    ConfigurableColumnsDummy.create!(title: 'Widget one', code: 'W1')
  end

  describe 'the index table' do
    it 'renders the declared defaults for an admin who never chose' do
      get admin_configurable_columns_dummies_path

      expect(response).to have_http_status(:ok)
      expect(rendered_columns).to include(*registry.default_keys)
      expect(rendered_columns).not_to include(:code)
    end

    it 'renders the columns the admin saved' do
      AdminTablePreference.store(admin: admin, resource_key: resource_key, keys: %i[title code])

      get admin_configurable_columns_dummies_path

      expect(rendered_columns).to include(:title, :code)
      expect(rendered_columns).not_to include(:linked)
    end

    it 'is unaffected by what another admin saved' do
      AdminTablePreference.store(admin: create(:admin), resource_key: resource_key, keys: %i[code])

      get admin_configurable_columns_dummies_path

      expect(rendered_columns).to include(*registry.default_keys)
    end

    it 'runs a column block against the view, so view helpers work' do
      get admin_configurable_columns_dummies_path

      expect(response.body).to include('<a href="#">Widget one</a>')
    end

    it 'renders the columns picker in the sidebar' do
      get admin_configurable_columns_dummies_path

      expect(response.body).to include(I18n.t('active_admin.sidebars.columns'))
      expect(response.body).to include('name="visible_columns[]" id="configurable_columns_dummies_column_title"')
    end
  end

  describe 'the table columns page' do
    it 'lists every configurable table' do
      get admin_table_columns_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(resource.plural_resource_label)
      expect(response.body).to include("name=\"resource_key\" value=\"#{resource_key}\"")
    end
  end

  describe 'saving a selection' do
    it 'stores it for the current admin' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title code] }

      expect(response).to have_http_status(:see_other)
      expect(AdminTablePreference.visible_column_keys(admin, resource_key)).to eq(%i[title code])
    end

    it 'ignores keys the resource never declared' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: %w[title made_up] }

      expect(AdminTablePreference.visible_column_keys(admin, resource_key)).to eq(%i[title])
    end

    it 'stores the defaults when nothing is selected' do
      patch admin_table_columns_update_path,
            params: { resource_key: resource_key, visible_columns: [ '' ] }

      expect(AdminTablePreference.visible_column_keys(admin, resource_key)).to eq(registry.default_keys)
    end

    it 'refuses an unknown table' do
      patch admin_table_columns_update_path,
            params: { resource_key: 'made_up', visible_columns: %w[title] }

      expect(response).to have_http_status(:see_other)
      expect(AdminTablePreference.count).to eq(0)
    end
  end
end
