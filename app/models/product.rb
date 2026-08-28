class Product < ApplicationRecord
  belongs_to :brand, optional: true
  belongs_to :category, optional: true
  has_many :stock_items, dependent: :destroy
  has_many :warehouses, through: :stock_items

  enum :language, {
    ukrainian: "ukrainian",
    russian: "russian",
    english: "english",
    unknown: "unknown",
    not_applicable: "not applicable"
  },
  default: :unknown

  enum :site_status, {
    published: "published", not_published: "not_published", needs_review: "needs_review"
  }, default: :needs_review

  enum :packaging_condition, { ok: "ok", damaged: "damaged" }, default: :ok

  validates :manufacturer_name, presence: true
  validates :hp_url, presence: true, if: :published?
  validates :name, presence: true, if: :published?

  def total_quantity
    stock_items.sum(:quantity)
  end
end
