ActiveAdmin.register StockItem do
  menu parent: I18n.t("active_admin.menu.inventory"),
       priority: 5
  permit_params :product_id, :warehouse_id, :quantity, :damaged_quantity

  index do
    selectable_column

    column(:product) { |stock_item| product_name_and_sku(stock_item.product) }
    column :warehouse
    column :quantity
    column :damaged_quantity

    actions
  end

  filter :product
  filter :warehouse
  filter :quantity
  filter :damaged_quantity


  form do |f|
    f.inputs do
      f.input :product
      f.input :warehouse
      f.input :quantity
      f.input :damaged_quantity
    end
    f.actions
  end
end
