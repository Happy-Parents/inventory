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
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#
class Admin < ApplicationRecord
  include Ransackable
  include TranslatableEnum

  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  def self.unransackable_attributes
    %w[encrypted_password reset_password_token]
  end

  enum :role, { manager: 'manager', super_admin: 'super admin' }, default: :manager
  def role_condition_label = self.class.human_enum(:role, role)
end
