# class Admin < ApplicationRecord
#   has_many :inventory_audit_records, dependent: :nullify
# end

# class Warehouse < ApplicationRecord
#   has_many :stock_items, dependent: :destroy
#   has_many :products, through: :stock_items
#   has_many :inventory_audits, dependent: :destroy
# end

# class Product < ApplicationRecord
#   has_many :stock_items, dependent: :destroy
#   has_many :warehouses, through: :stock_items
# end

# class StockItem < ApplicationRecord
#   belongs_to :product
#   belongs_to :warehouse
#   has_many :inventory_audit_records, dependent: :destroy
# end

# class InventoryAudit < ApplicationRecord
#   belongs_to :warehouse
#   has_many :inventory_audit_records, dependent: :destroy

#   # additional columns

#   enum :status, {
#     in_progress: "in progress",
#     completed: "completed",
#     canceled: "canceled"
#   },
#   default: :in_progress

#   # completed_at :timestamp

# class InventoryAuditRecord < ApplicationRecord
#   belongs_to :inventory_audit
#   belongs_to :admin, optional: true
#   belongs_to :stock_item
# end
