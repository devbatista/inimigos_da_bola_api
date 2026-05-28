require "digest"

class RefreshToken < ApplicationRecord
  TOKEN_TTL = 30.days

  before_validation :assign_uuid_v7, on: :create

  belongs_to :user

  validates :token_digest, :expires_at, presence: true
  validates :token_digest, uniqueness: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for(user)
    raw_token = SecureRandom.urlsafe_base64(48)
    refresh_token = create!(
      user: user,
      token_digest: digest(raw_token),
      expires_at: TOKEN_TTL.from_now
    )

    [ raw_token, refresh_token ]
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def assign_uuid_v7
    self.id ||= SecureRandom.uuid_v7
  end
end
