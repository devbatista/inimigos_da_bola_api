module Api
  module V1
    module WeeklySessions
      class StatsController < ApplicationController
        before_action :authenticate_user!

        def create
          authorize ::SessionStat, :create?

          weekly_session = ::WeeklySession.active.find(params[:weekly_session_id])

          result = ::SessionStats::UpsertBatch.new(
            weekly_session: weekly_session,
            stats: stats_params
          ).call

          if result.success?
            render json: SessionStatBlueprint.render_as_hash(result.data), status: :ok
          else
            render_error(result.code, result.message, :unprocessable_entity)
          end
        end

        private

        def stats_params
          params.permit(stats: [ :user_id, :goals, :assists ])
            .fetch(:stats, [])
            .map { |entry| entry.to_h.symbolize_keys }
        end
      end
    end
  end
end
