class ReviewModelConstraints < ActiveRecord::Migration[8.1]
  UUID_V7_TABLES = %i[
    users
    weekly_sessions
    attendances
    skill_ratings
    session_stats
    refresh_tokens
  ].freeze

  def change
    UUID_V7_TABLES.each do |table_name|
      change_column_default table_name, :id, from: -> { "gen_random_uuid()" }, to: nil
    end

    add_index :weekly_sessions, :scheduled_at,
      unique: true,
      where: "deleted_at IS NULL",
      name: "idx_weekly_sessions_scheduled_at_active_unique"

    add_check_constraint :attendances,
      "(kind = 'registered' AND created_by_admin_id IS NULL) OR (kind = 'guest' AND created_by_admin_id IS NOT NULL)",
      name: "attendances_created_by_admin_check"

    add_check_constraint :attendances,
      "waitlist_position IS NULL OR waitlist_position > 0",
      name: "attendances_waitlist_position_check"
  end
end
