Rails.application.config.after_initialize do
  ActiveadminConfigurableColumns.configure do |config|
    config.menu = {
      parent: I18n.t('active_admin.menu.settings'),
      priority: 0,
      label: proc { I18n.t('active_admin.table_columns.title') }
    }
  end
end
