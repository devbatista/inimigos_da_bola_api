module Api
  module V1
    class StatsController < ApplicationController
      before_action :authenticate_user!

      ALLOWED_PERIODS = %w[month year].freeze
      DEFAULT_PERIOD = "month".freeze

      def leaderboard
        authorize ::SessionStat, :leaderboard?

        rows = ::SessionStat.active
          .joins(:weekly_session)
          .where(weekly_sessions: { deleted_at: nil, scheduled_at: period_range })
          .group(:user_id)
          .select(
            "user_id",
            "SUM(goals) AS goals",
            "SUM(assists) AS assists",
            "COUNT(*) AS games"
          )
          .order(Arel.sql("SUM(goals) DESC, SUM(assists) DESC"))

        render json: { period: period, leaderboard: build_leaderboard(rows) }, status: :ok
      end

      private

      def period
        @period ||= ALLOWED_PERIODS.include?(params[:period]) ? params[:period] : DEFAULT_PERIOD
      end

      def period_range
        period == "year" ? Time.current.all_year : Time.current.all_month
      end

      def build_leaderboard(rows)
        users = ::User.where(id: rows.map(&:user_id)).index_by(&:id)

        rows.map do |row|
          {
            user_id: row.user_id,
            name: users[row.user_id]&.name,
            goals: row.goals.to_i,
            assists: row.assists.to_i,
            games: row.games.to_i
          }
        end
      end
    end
  end
end
