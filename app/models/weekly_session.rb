class WeeklySession < ApplicationRecord
  include SyncRecord

  enum :status, { scheduled: "scheduled", closed: "closed", canceled: "canceled" }

  has_many :attendances, dependent: :restrict_with_error
  has_many :session_stats, dependent: :restrict_with_error

  validates :scheduled_at, presence: true
  validates :scheduled_at, uniqueness: { conditions: -> { active } }
  validates :max_players, numericality: { only_integer: true, greater_than: 0 }
end
