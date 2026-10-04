module MyAccountHelper
  def telegram_panel_title
    safe_join([
      render('admin/telegram_logo'),
      t('active_admin.my_account.telegram_panel')
    ]
    )
  end

  def configurable_columns_resources
    ActiveadminConfigurableColumns.resources(active_admin_namespace).select do |resource|
      authorized?(ActiveAdmin::Authorization::READ, resource.resource_class)
    end
  end
end
