ActiveAdmin.register Warehouse do
  menu parent: I18n.t('active_admin.menu.inventory'),
       priority: 4
  permit_params :name

  index do
    selectable_column

    column :name
    column(:products_count) { |warehouse| warehouse.products.count }

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
