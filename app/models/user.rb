require "digest"

class User < ApplicationRecord
  INVITATION_TOKEN_TTL = 7.days

  include Devise::JWT::RevocationStrategies::JTIMatcher
  include SyncRecord

  devise :database_authenticatable,
    :recoverable,
    :jwt_authenticatable,
    jwt_revocation_strategy: self

  enum :player_type, { monthly: "monthly", casual: "casual" }

  has_many :attendances, dependent: :restrict_with_error
  has_many :created_guest_attendances,
    class_name: "Attendance",
    foreign_key: :created_by_admin_id,
    inverse_of: :created_by_admin,
    dependent: :restrict_with_error
  has_many :given_skill_ratings,
    class_name: "SkillRating",
    foreign_key: :evaluator_user_id,
    inverse_of: :evaluator_user,
    dependent: :restrict_with_error
  has_many :received_skill_ratings,
    class_name: "SkillRating",
    foreign_key: :evaluated_user_id,
    inverse_of: :evaluated_user,
    dependent: :restrict_with_error
  has_many :session_stats, dependent: :restrict_with_error
  has_many :refresh_tokens, dependent: :delete_all

  before_validation :assign_jti, on: :create

  validates :name, presence: true
  validates :email,
    format: { with: Devise.email_regexp },
    uniqueness: { conditions: -> { active } },
    allow_nil: true
  validate :email_required_unless_pending_invitation
  validates :password,
    confirmation: true,
    length: { within: Devise.password_length },
    allow_nil: true
  validates :skill_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  def self.digest_invitation_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.find_pending_invitation(raw_token)
    active
      .where(invitation_accepted_at: nil)
      .where(invitation_token: digest_invitation_token(raw_token.to_s))
      .where("invitation_expires_at > ?", Time.current)
      .first
  end

  def issue_invitation!
    raw_token = SecureRandom.urlsafe_base64(32)
    update!(
      invitation_token: self.class.digest_invitation_token(raw_token),
      invitation_sent_at: Time.current,
      invitation_expires_at: INVITATION_TOKEN_TTL.from_now,
      invitation_accepted_at: nil
    )

    raw_token
  end

  def accept_invitation!(email:, password:, password_confirmation:, player_type:, goalkeeper:, name: nil)
    update!(
      name: name.presence || self.name,
      email: email.to_s.downcase,
      password: password,
      password_confirmation: password_confirmation.presence || password,
      player_type: player_type.presence || "casual",
      goalkeeper: ActiveModel::Type::Boolean.new.cast(goalkeeper),
      invitation_token: nil,
      invitation_expires_at: nil,
      invitation_accepted_at: Time.current
    )
  end

  private

  def assign_jti
    self.jti ||= SecureRandom.uuid
  end

  def email_required_unless_pending_invitation
    return if email.present?
    return if pending_invitation?

    errors.add(:email, :blank)
  end

  def pending_invitation?
    invitation_accepted_at.nil? && encrypted_password.blank?
  end
end
