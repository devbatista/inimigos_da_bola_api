class RefreshToken < ApplicationRecord
  before_validation :assign_uuid_v7, on: :create

  belongs_to :user

  validates :token_digest, :expires_at, presence: true
  validates :token_digest, uniqueness: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def revoked?
    revoked_at.present?
  end

  private

  def assign_uuid_v7
    self.id ||= SecureRandom.uuid_v7
  end
end
