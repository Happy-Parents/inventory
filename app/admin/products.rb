ActiveAdmin.register Product do
  permit_params :manufacturer_name, :name, :manufacturer_sku, :sku,
                :brand_id, :category_id, :language, :site_status,
                :packaging_condition, :hp_url, :notes

  index do
    selectable_column

    column :manufacturer_name
    column :name
    column :brand
    column :category
    column :sku
    column :manufacturer_sku
    column :language
    column :site_status
    column :packaging_condition
    column("Qty") { |product| product.total_quantity }
    actions
  end

  filter :manufacturer_name
  filter :name
  filter :sku
  filter :manufacturer_sku
  filter :brand
  filter :category
  filter :language, as: :select, collection: Product.languages
  filter :site_status, as: :select, collection: Product.site_statuses
  filter :packaging_condition, as: :select, collection: Product.packaging_conditions

  form do |f|
    f.inputs do
      f.input :manufacturer_name
      f.input :name
      f.input :brand
      f.input :category
      f.input :manufacturer_sku
      f.input :sku
      f.input :language, as: :select, collection: Product.languages.keys
      f.input :site_status, as: :select, collection: Product.site_statuses.keys
      f.input :packaging_condition, as: :select, collection: Product.packaging_conditions.keys
      f.input :hp_url
      f.input :notes
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :manufacturer_name
      row :name
      row :brand
      row :category
      row :manufacturer_sku
      row :sku
      row :language
      row :site_status
      row :packaging_condition
      row :hp_url
      row :notes
      row("Total quantity") { |product| product.total_quantity }
      row :created_at
      row :updated_at
    end

    panel "Stock" do
      table_for product.stock_items do
        column :warehouse
        column :quantity
        column :damaged_quantity
      end
    end

    active_admin_comments_for(resource)
  end
end
