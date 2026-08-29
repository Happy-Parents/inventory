ActiveAdmin.register Category do
  menu priority: 2
  permit_params :name, :parent_id

  index do
    selectable_column

    column :name
    column :parent
    column("Products") { |category| category.products.count }
    actions
  end

  filter :name
  filter :parent

  form do |f|
    f.inputs do
      f.input :name
      f.input :parent, as: :select,
                        collection: Category.where.not(id: f.object.id).order(:name) # Exclude self.
    end
    f.actions
  end
end
