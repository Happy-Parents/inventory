class Admin < ApplicationRecord
  include Ransackable

  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  def self.unransackable_attributes
    %w[encrypted_password reset_password_token]
  end
end
