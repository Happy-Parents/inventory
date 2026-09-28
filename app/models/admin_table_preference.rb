# One row per admin per ActiveAdmin index table, holding the columns that admin
# chose to see there. The available columns themselves are declared in
# app/admin/*.rb with the `configurable_columns` DSL -- see
# lib/configurable_columns.rb.
# == Schema Information
#
# Table name: admin_table_preferences
#
#  id              :uuid             not null, primary key
#  resource_key    :string           not null
#  visible_columns :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  admin_id        :uuid             not null
#
# Indexes
#
#  index_admin_table_preferences_on_admin_id                   (admin_id)
#  index_admin_table_preferences_on_admin_id_and_resource_key  (admin_id,resource_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (admin_id => admins.id)
#
class AdminTablePreference < ApplicationRecord
  belongs_to :admin

  validates :resource_key, presence: true,
                           uniqueness: { scope: :admin_id, case_sensitive: false }
  validate :visible_columns_must_be_an_array

  # Returns the keys this admin picked for the table, or nil when they never
  # saved anything (the caller then falls back to the declared defaults).
  def self.visible_column_keys(admin, resource_key)
    return nil if admin.blank?

    find_by(admin_id: admin.id, resource_key: resource_key)&.visible_columns&.map(&:to_sym)
  end

  def self.store(admin:, resource_key:, keys:)
    preference = find_or_initialize_by(admin: admin, resource_key: resource_key)
    preference.update!(visible_columns: keys.map(&:to_s))
    preference
  end

  private

  def visible_columns_must_be_an_array
    return if visible_columns.is_a?(Array)

    errors.add(:visible_columns, :invalid)
  end
end
