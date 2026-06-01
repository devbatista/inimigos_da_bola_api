module GuestAttendances
  class Destroy
    def initialize(attendance:)
      @attendance = attendance
    end

    def call
      return ServiceResult.failure("ATTENDANCE_LOCKED", "A presença não pode mais ser alterada.") if locked?

      was_in_main_list = @attendance.confirmed? && @attendance.waitlist_position.nil?

      @attendance.soft_delete!

      Attendances::PromoteWaitlist.new(weekly_session: @attendance.weekly_session).call if was_in_main_list

      notify_admins

      ServiceResult.success(@attendance)
    end

    private

    def locked?
      Time.current >= @attendance.weekly_session.scheduled_at
    end

    # Avisa os admins sobre o avulso removido e dispara o sync silencioso.
    def notify_admins
      Notifications::PushJob.perform_later(
        audience: "admins",
        title: "Avulso removido",
        body: "#{@attendance.guest_name} foi removido do racha.",
        data: { weekly_session_id: @attendance.weekly_session_id, type: "guest_removed", attendance_id: @attendance.id }
      )
      Notifications::PushJob.perform_later(
        audience: "all",
        data: { weekly_session_id: @attendance.weekly_session_id, type: "sync" }
      )
    end
  end
end
