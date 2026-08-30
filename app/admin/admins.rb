ActiveAdmin.register Admin do
  permit_params :email, :password, :password_confirmation

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
      f.input :role
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
