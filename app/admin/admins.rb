ActiveAdmin.register Admin do
  menu parent: I18n.t('active_admin.menu.settings'),
       priority: 1
  permit_params :email, :role, :password, :password_confirmation

  index do
    selectable_column

    column :email
    column(:role) { |admin| admin.role_condition_label }

    actions
  end

  filter :role, as: :select, collection: -> { Admin.enum_options(:role) }

  form do |f|
    f.inputs do
      f.input :email
      f.input :role, as: :select, collection: Admin.enum_options(:role)
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
