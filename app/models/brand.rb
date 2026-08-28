class Brand < ApplicationRecord
  include Ransackable

  has_many :products, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
