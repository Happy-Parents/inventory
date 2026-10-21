# == Schema Information
#
# Table name: api_sessions
#
#  id                   :uuid             not null, primary key
#  device_name          :string
#  expires_at           :datetime         not null
#  provider             :string           not null
#  refresh_token_digest :string           not null
#  revoked_at           :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  admin_id             :uuid             not null
#
# Indexes
#
#  index_api_sessions_on_admin_id              (admin_id)
#  index_api_sessions_on_refresh_token_digest  (refresh_token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (admin_id => admins.id)
#
# A signed-in client app. Holds the refresh-token state: only a SHA-256 digest
# of the current refresh token is stored, and every refresh replaces it
class ApiSession < ApplicationRecord
  REFRESH_TOKEN_TTL = 30.days
  PROVIDERS = %w[password google_oauth2 github telegram apple].freeze

  belongs_to :admin

  validates :provider, inclusion: { in: PROVIDERS }

  scope :active, -> { where(revoked_at: nil, expires_at: Time.current..) }

  def self.digest(secret) = OpenSSL::Digest::SHA256.hexdigest(secret)

  def active? = revoked_at.nil? && expires_at.future?
end
