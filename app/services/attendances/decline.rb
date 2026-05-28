module Attendances
  class Decline
    def initialize(weekly_session:, user:)
      @weekly_session = weekly_session
      @user = user
    end

    def call
      return ServiceResult.failure("ATTENDANCE_LOCKED", "A presença não pode mais ser alterada.") if locked?

      attendance = @weekly_session.attendances
        .where(user: @user, kind: :registered, deleted_at: nil)
        .first_or_initialize

      was_in_main_list = attendance.persisted? && attendance.confirmed? && attendance.waitlist_position.nil?

      attendance.status = :declined
      attendance.waitlist_position = nil
      attendance.save!

      Attendances::PromoteWaitlist.new(weekly_session: @weekly_session).call if was_in_main_list

      ServiceResult.success(attendance)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence)
    end

    private

    def locked?
      Time.current >= @weekly_session.scheduled_at
    end
  end
end
