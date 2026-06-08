module Sync
  class CleanupTombstonesJob < ApplicationJob
    queue_as :default

    RETENTION_PERIOD = 90.days

    def perform(now: Time.current)
      cutoff = now - RETENTION_PERIOD

      {
        session_stats: delete_old(SessionStat, cutoff),
        skill_ratings: delete_old(SkillRating, cutoff),
        attendances: delete_old(Attendance, cutoff),
        weekly_sessions: delete_old(deletable_weekly_sessions(cutoff), cutoff),
        users: delete_old(deletable_users(cutoff), cutoff)
      }
    end

    private

    def delete_old(target, cutoff)
      scope = target.is_a?(Class) ? target.all : target
      scope.where(scope.klass.arel_table[:deleted_at].lt(cutoff)).delete_all
    end

    def deletable_weekly_sessions(cutoff)
      WeeklySession
        .where(WeeklySession.arel_table[:deleted_at].lt(cutoff))
        .where.not(id: Attendance.select(:weekly_session_id))
        .where.not(id: SessionStat.select(:weekly_session_id))
    end

    def deletable_users(cutoff)
      User
        .where(User.arel_table[:deleted_at].lt(cutoff))
        .where.not(id: Attendance.where.not(user_id: nil).select(:user_id))
        .where.not(id: Attendance.where.not(created_by_admin_id: nil).select(:created_by_admin_id))
        .where.not(id: SkillRating.select(:evaluator_user_id))
        .where.not(id: SkillRating.select(:evaluated_user_id))
        .where.not(id: SessionStat.select(:user_id))
        .where.not(id: RefreshToken.select(:user_id))
    end
  end
end
