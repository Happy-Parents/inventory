if Rails.env.development?
  Admin.find_or_create_by!(email: "happyparentsua@gmail.com") do |admin|
    admin.role = Admin.roles[:super_admin]
    admin.password = "mubwat-syzmoJ-3jisto"
    admin.password_confirmation = "mubwat-syzmoJ-3jisto"
  end
end
