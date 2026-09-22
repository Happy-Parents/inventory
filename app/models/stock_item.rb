# == Schema Information
#
# Table name: stock_items
#
#  id               :uuid             not null, primary key
#  damaged_quantity :integer          default(0), not null
#  quantity         :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  product_id       :uuid             not null
#  warehouse_id     :uuid             not null
#
# Indexes
#
#  index_stock_items_on_product_id                   (product_id)
#  index_stock_items_on_product_id_and_warehouse_id  (product_id,warehouse_id) UNIQUE
#  index_stock_items_on_warehouse_id                 (warehouse_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (warehouse_id => warehouses.id)
#
class StockItem < ApplicationRecord
  include Ransackable

  belongs_to :product
  belongs_to :warehouse

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :damaged_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: :warehouse_id }
end
