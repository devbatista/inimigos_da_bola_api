module Api
  module V1
    module WeeklySessions
      class AttendancesController < ApplicationController
        ALLOWED_STATUSES = %w[confirmed declined].freeze

        before_action :authenticate_user!

        def create
          authorize ::Attendance, :create?

          status = attendance_params[:status].to_s
          unless ALLOWED_STATUSES.include?(status)
            return render_error("VALIDATION_ERROR", "Status inválido.", :unprocessable_entity)
          end

          weekly_session = ::WeeklySession.active.find(params[:weekly_session_id])

          result = service_for(status).new(weekly_session: weekly_session, user: current_user).call

          if result.success?
            render json: AttendanceBlueprint.render_as_hash(result.data), status: :ok
          else
            render_error(result.code, result.message, :unprocessable_entity)
          end
        end

        private

        def attendance_params
          params.permit(:status)
        end

        def service_for(status)
          status == "confirmed" ? ::Attendances::Confirm : ::Attendances::Decline
        end
      end
    end
  end
end
