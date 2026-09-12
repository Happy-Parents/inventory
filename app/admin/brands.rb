ActiveAdmin.register Brand do
  menu parent: I18n.t("active_admin.menu.inventory"),
       priority: 3
  permit_params :name

  index do
    selectable_column

    column :name
    column(:products_count) { |brand| brand.products.count }
    actions
  end

  filter :name

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end
end
