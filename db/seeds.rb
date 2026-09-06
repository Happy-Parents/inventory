admin_creds = Rails.application.credentials.dig(:default_superadmin)
Admin.find_or_create_by!(email: admin_creds[:email]) do |admin|
  admin.role = Admin.roles[:super_admin]
  admin.password = admin_creds[:password]
  admin.password_confirmation = admin_creds[:password]
end
