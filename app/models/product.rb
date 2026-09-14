class Product < ApplicationRecord
  include Ransackable
  include TranslatableEnum

  belongs_to :brand, optional: true
  belongs_to :category, optional: true
  has_many :stock_items, dependent: :destroy
  has_many :warehouses, through: :stock_items

  accepts_nested_attributes_for :stock_items, allow_destroy: true

  enum :language, {
    ukrainian: 'ukrainian',
    russian: 'russian',
    english: 'english',
    unknown: 'unknown',
    not_applicable: 'not applicable'
  },
  default: :unknown

  enum :site_status, {
    published: 'published', not_published: 'not_published', needs_review: 'needs_review'
  }, default: :needs_review

  enum :packaging_condition, { ok: 'ok', damaged: 'damaged' }, default: :ok

  validates :manufacturer_name, presence: true
  validates :hp_url, presence: true, if: :published?
  validates :name, presence: true, if: :published?

  def total_quantity
    stock_items.sum(:quantity)
  end

  def language_label            = self.class.human_enum(:language, language)
  def site_status_label         = self.class.human_enum(:site_status, site_status)
  def packaging_condition_label = self.class.human_enum(:packaging_condition, packaging_condition)
end
