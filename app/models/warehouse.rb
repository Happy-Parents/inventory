class Warehouse < ApplicationRecord
  include Ransackable

  has_many :stock_items, dependent: :destroy
  has_many :products, through: :stock_items

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
