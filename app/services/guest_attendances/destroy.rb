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

      ServiceResult.success(@attendance)
    end

    private

    def locked?
      Time.current >= @attendance.weekly_session.scheduled_at
    end
  end
end
