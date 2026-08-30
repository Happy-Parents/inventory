class Admin < ApplicationRecord
  include Ransackable
  include TranslatableEnum

  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  def self.unransackable_attributes
    %w[encrypted_password reset_password_token]
  end

  enum :role, { manager: "manager", super_admin: "super admin" }, default: :manager
  def role_condition_label = self.class.human_enum(:role, role)
end
