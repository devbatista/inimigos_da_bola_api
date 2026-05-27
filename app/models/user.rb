class User < ApplicationRecord
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
    presence: true,
    format: { with: Devise.email_regexp },
    uniqueness: { conditions: -> { active } }
  validates :password,
    confirmation: true,
    length: { within: Devise.password_length },
    allow_nil: true
  validates :skill_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  private

  def assign_jti
    self.jti ||= SecureRandom.uuid
  end
end
