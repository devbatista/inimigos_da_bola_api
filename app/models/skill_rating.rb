class SkillRating < ApplicationRecord
  include SyncRecord

  belongs_to :evaluator_user, class_name: "User"
  belongs_to :evaluated_user, class_name: "User"

  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :evaluator_user_id, uniqueness: { scope: :evaluated_user_id, conditions: -> { active } }
  validate :evaluator_cannot_rate_self

  private

  def evaluator_cannot_rate_self
    return if evaluator_user_id.blank? || evaluated_user_id.blank?
    return unless evaluator_user_id == evaluated_user_id

    errors.add(:evaluated_user_id, :invalid)
  end
end
