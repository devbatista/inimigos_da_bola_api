module GuestAttendances
  class Create
    def initialize(weekly_session:, admin:, guest_name:)
      @weekly_session = weekly_session
      @admin = admin
      @guest_name = guest_name
    end

    def call
      return ServiceResult.failure("ATTENDANCE_LOCKED", "A presença não pode mais ser alterada.") if locked?

      attendance = @weekly_session.attendances.new(
        kind: :guest,
        status: :confirmed,
        guest_name: @guest_name,
        created_by_admin: @admin,
        waitlist_position: compute_waitlist_position
      )
      attendance.save!

      ServiceResult.success(attendance)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence)
    end

    private

    def locked?
      Time.current >= @weekly_session.scheduled_at
    end

    def compute_waitlist_position
      occupied = @weekly_session.attendances.active
        .where(status: :confirmed, waitlist_position: nil)
        .count

      return nil if occupied < @weekly_session.max_players

      max = @weekly_session.attendances.active
        .where(status: :confirmed)
        .where.not(waitlist_position: nil)
        .maximum(:waitlist_position) || 0

      max + 1
    end
  end
end
