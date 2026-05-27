class SkillRatingPolicy < ApplicationPolicy
  def create?
    user.present?
  end
end
