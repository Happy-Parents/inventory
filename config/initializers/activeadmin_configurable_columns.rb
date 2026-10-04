Rails.application.config.after_initialize do
  ActiveadminConfigurableColumns.configure do |config|
    config.menu = false
  end
end
