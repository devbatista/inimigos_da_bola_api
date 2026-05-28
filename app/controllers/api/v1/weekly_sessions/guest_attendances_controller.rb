module Api
  module V1
    module WeeklySessions
      class GuestAttendancesController < ApplicationController
        before_action :authenticate_user!

        def create
          authorize :guest_attendance, :create?

          weekly_session = ::WeeklySession.active.find(params[:weekly_session_id])
          guest_name = guest_params[:guest_name].to_s.strip

          if guest_name.blank?
            return render_error("VALIDATION_ERROR", "Nome do avulso é obrigatório.", :unprocessable_entity)
          end

          result = ::GuestAttendances::Create.new(
            weekly_session: weekly_session,
            admin: current_user,
            guest_name: guest_name
          ).call

          if result.success?
            render json: AttendanceBlueprint.render_as_hash(result.data), status: :created
          else
            render_error(result.code, result.message, :unprocessable_entity)
          end
        end

        def destroy
          authorize :guest_attendance, :destroy?

          weekly_session = ::WeeklySession.active.find(params[:weekly_session_id])
          attendance = weekly_session.attendances.active.guest.find(params[:id])

          result = ::GuestAttendances::Destroy.new(attendance: attendance).call

          if result.success?
            head :no_content
          else
            render_error(result.code, result.message, :unprocessable_entity)
          end
        end

        private

        def guest_params
          params.permit(:guest_name)
        end
      end
    end
  end
end
