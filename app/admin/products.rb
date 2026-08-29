ActiveAdmin.register Product do
  menu priority: 1
  permit_params :manufacturer_name, :name, :manufacturer_sku, :sku,
                :brand_id, :category_id, :language, :site_status,
                :packaging_condition, :hp_url, :notes

  # ТМ	Назва виробника	Назва на сайті	Арт. зовн.	Арт. внутр.	Кількість	Категорія	Пакування	Наявність на сайті	Мова	Нотатки	Склад
  index do
    selectable_column

    column :brand
    column :manufacturer_sku
    column :manufacturer_name
    column :sku
    column :name
    column("Qty") { |product| product.total_quantity }
    column :category
    column :packaging_condition
    column :site_status
    column :hp_url
    column :language
    column :notes
    column("Warehouse") { |product| product.warehouses.pluck(:name) }
    actions
  end

  filter :brand
  filter :manufacturer_sku
  filter :manufacturer_name
  filter :sku
  filter :name
  filter :stock_items_quantity, as: :numeric, label: "Qty"
  filter :category
  filter :packaging_condition, as: :select, collection: Product.packaging_conditions
  filter :site_status, as: :select, collection: Product.site_statuses
  filter :hp_url
  filter :language, as: :select, collection: Product.languages
  filter :notes
  filter :warehouses, as: :select, collection: -> { Warehouse.order(:name) }, label: "Warehouses"

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
