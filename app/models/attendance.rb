class Attendance < ApplicationRecord
  include SyncRecord

  enum :kind, { registered: "registered", guest: "guest" }
  enum :status, { confirmed: "confirmed", declined: "declined", pending: "pending" }

  belongs_to :weekly_session
  belongs_to :user, optional: true
  belongs_to :created_by_admin, class_name: "User", optional: true

  validates :kind, :status, presence: true
  validates :user_id, presence: true, if: :registered?
  validates :guest_name, presence: true, if: :guest?
  validates :created_by_admin_id, presence: true, if: :guest?
  validates :user_id, absence: true, if: :guest?
  validates :guest_name, absence: true, if: :registered?
  validates :created_by_admin_id, absence: true, if: :registered?
  validates :waitlist_position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :user_id, uniqueness: {
    scope: :weekly_session_id,
    conditions: -> { active.registered },
    allow_nil: true
  }
end
