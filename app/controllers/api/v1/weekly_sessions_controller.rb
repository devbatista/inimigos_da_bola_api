module Api
  module V1
    class WeeklySessionsController < ApplicationController
      before_action :authenticate_user!

      def current
        authorize WeeklySession, :current?

        result = WeeklySessions::CreateCurrent.new.call
        if result.success?
          render json: WeeklySessionBlueprint.render_as_hash(result.data)
        else
          render_error(result.code, result.message, :unprocessable_entity)
        end
      end

      def show
        weekly_session = WeeklySession.active.find(params[:id])
        authorize weekly_session

        render json: WeeklySessionBlueprint.render_as_hash(weekly_session)
      end
    end
  end
end
