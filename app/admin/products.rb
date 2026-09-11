ActiveAdmin.register Product do
  config.per_page = [10, 25, 50, 100, 500]

  menu parent: I18n.t("active_admin.menu.inventory"),
       priority: 1
  permit_params :manufacturer_name, :name, :manufacturer_sku, :sku,
                :brand_id, :category_id, :language, :site_status,
                :packaging_condition, :hp_url, :notes,
                stock_items_attributes: [ :id, :warehouse_id, :quantity, :damaged_quantity, :_destroy ]

  index do
    selectable_column

    column :brand
    column :manufacturer_sku
    column :manufacturer_name
    column :sku
    column :name
    column(:qty) { |product| product.total_quantity }
    column :category
    column(:packaging_condition) { |product| product.packaging_condition_label }
    column(:site_status) { |product| product.site_status_label }
    column :hp_url
    column(:language) { |product| product.language_label }
    column :notes
    column(:warehouse) { |product| product.warehouses.pluck(:name) }
    actions
  end

  filter :brand
  filter :manufacturer_sku
  filter :manufacturer_name
  filter :sku
  filter :name
  filter :stock_items_quantity, as: :numeric, label: -> { Product.human_attribute_name(:qty) }
  filter :category
  filter :packaging_condition, as: :select, collection: -> { Product.enum_options(:packaging_condition) }
  filter :site_status, as: :select, collection: -> { Product.enum_options(:site_status) }
  filter :hp_url
  filter :language, as: :select, collection: -> { Product.enum_options(:language) }
  filter :notes
  filter :warehouses, as: :select, collection: -> { Warehouse.order(:name) }, label: -> { Product.human_attribute_name(:warehouse) }

  form do |f|
    f.inputs do
      f.input :manufacturer_name
      f.input :name
      f.input :brand
      f.input :category
      f.input :manufacturer_sku
      f.input :sku
      f.input :language, as: :select, collection: Product.enum_options(:language)
      f.input :site_status, as: :select, collection: Product.enum_options(:site_status)
      f.input :packaging_condition, as: :select, collection: Product.enum_options(:packaging_condition)
      f.input :hp_url
      f.input :notes
    end

    f.inputs I18n.t("active_admin.stock") do
      f.has_many :stock_items, heading: false, allow_destroy: true, new_record: "Add stock" do |si|
        si.input :warehouse
        si.input :quantity
        si.input :damaged_quantity
      end
    end

    f.actions
  end

  show title: :manufacturer_name do
    attributes_table do
      row :id
      row :manufacturer_name
      row :name
      row :brand
      row :category
      row :manufacturer_sku
      row :sku
      row(:language) { |product| product.language_label }
      row(:site_status) { |product| product.site_status_label }
      row(:packaging_condition) { |product| product.packaging_condition_label }
      row :hp_url
      row :notes
      row("Total quantity") { |product| product.total_quantity }
      row :created_at
      row :updated_at
    end

    panel I18n.t("active_admin.stock") do
      table_for product.stock_items do
        column :warehouse
        column :quantity
        column :damaged_quantity
      end
    end

    active_admin_comments_for(resource)
  end
end
