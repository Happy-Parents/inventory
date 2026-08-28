class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, dependent: :nullify
  has_many :products, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
