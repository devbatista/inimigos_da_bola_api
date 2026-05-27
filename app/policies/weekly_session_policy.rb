class WeeklySessionPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def current?
    show?
  end
end
