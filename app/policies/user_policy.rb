class UserPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def invite?
    user&.admin?
  end
end
