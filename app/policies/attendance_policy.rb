class AttendancePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    record.user_id == user&.id
  end
end
