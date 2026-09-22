# == Schema Information
#
# Table name: warehouses
#
#  id         :uuid             not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_warehouses_on_name  (name) UNIQUE
#
class Warehouse < ApplicationRecord
  include Ransackable

  has_many :stock_items, dependent: :destroy
  has_many :products, through: :stock_items

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
