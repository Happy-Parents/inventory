ActiveAdmin.register Brand do
  permit_params :name

  index do
    selectable_column

    column :name
    column("Products") { |brand| brand.products.count }
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
