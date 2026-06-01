class SessionStatPolicy < ApplicationPolicy
  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def leaderboard?
    user.present?
  end
end
