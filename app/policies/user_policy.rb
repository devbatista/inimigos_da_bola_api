class UserPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def update?
    record == user
  end

  def invite?
    user&.admin?
  end
end
