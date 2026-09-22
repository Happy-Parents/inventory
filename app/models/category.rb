# == Schema Information
#
# Table name: categories
#
#  id         :uuid             not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :uuid
#
# Indexes
#
#  index_categories_on_name       (name) UNIQUE
#  index_categories_on_parent_id  (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => categories.id)
#
class Category < ApplicationRecord
  include Ransackable

  belongs_to :parent, class_name: 'Category', optional: true
  has_many :subcategories, class_name: 'Category', foreign_key: :parent_id, dependent: :nullify
  has_many :products, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
