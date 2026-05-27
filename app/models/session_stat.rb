class SessionStat < ApplicationRecord
  include SyncRecord

  belongs_to :weekly_session
  belongs_to :user

  validates :user_id, uniqueness: { scope: :weekly_session_id, conditions: -> { active } }
  validates :goals, :assists, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
