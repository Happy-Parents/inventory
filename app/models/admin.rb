# == Schema Information
#
# Table name: admins
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("manager"), not null
#  telegram_username      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  telegram_id            :bigint
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#  index_admins_on_telegram_id           (telegram_id) UNIQUE
#
class Admin < ApplicationRecord
  include Ransackable
  include TranslatableEnum
devise :database_authenticatable, :rememberable, :validatable,
       :omniauthable, omniauth_providers: [ :google_oauth2, :github ]

  has_many :table_preferences, class_name: 'ActiveadminConfigurableColumns::Preference',
                               as: :admin, dependent: :destroy

  def self.unransackable_attributes
    %w[encrypted_password reset_password_token]
  end

  enum :role, { manager: 'manager', super_admin: 'super admin' }, default: :manager
  def role_condition_label = self.class.human_enum(:role, role)

  protected

  def password_required?
    password.present? || password_confirmation.present?
  end
end
