# Central place to review and change visible table columns at once,
# and the same form is rendered in the
# "Columns" sidebar of every configurable index.
ActiveAdmin.register_page 'Table columns' do
  menu parent: I18n.t('active_admin.menu.settings'),
       priority: 0,
       label: proc { I18n.t('active_admin.table_columns.title') }

  content title: proc { I18n.t('active_admin.table_columns.title') } do
    resources = ConfigurableColumns.resources(active_admin_namespace).select do |resource|
      authorized?(ActiveAdmin::Authorization::READ, resource.resource_class)
    end

    render 'admin/table_columns/page', resources: resources
  end

  page_action :update, method: :patch do
    resource = ConfigurableColumns.resource_for(active_admin_namespace, params[:resource_key])

    if resource.nil?
      redirect_back fallback_location: admin_root_path,
                    status: :see_other,
                    alert: t('active_admin.table_columns.unknown_resource')
    else
      registry = resource.column_registry

      AdminTablePreference.store(admin: current_active_admin_user,
                                 resource_key: registry.resource_key,
                                 keys: registry.selected_keys(params[:visible_columns]))

      redirect_back fallback_location: admin_table_columns_path,
                    status: :see_other,
                    notice: t('active_admin.table_columns.saved')
    end
  end
end
