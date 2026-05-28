module Attendances
  class Confirm
    def initialize(weekly_session:, user:)
      @weekly_session = weekly_session
      @user = user
    end

    def call
      return ServiceResult.failure("ATTENDANCE_LOCKED", "A presença não pode mais ser alterada.") if locked?

      attendance = @weekly_session.attendances
        .where(user: @user, kind: :registered, deleted_at: nil)
        .first_or_initialize do |record|
          record.status = :confirmed
        end

      return ServiceResult.success(attendance) if attendance.persisted? && attendance.confirmed? && !attendance.waitlist_position

      attendance.status = :confirmed
      attendance.waitlist_position = compute_waitlist_position(exclude: attendance)
      attendance.save!

      ServiceResult.success(attendance)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence)
    end

    private

    def locked?
      Time.current >= @weekly_session.scheduled_at
    end

    # Conta confirmados na lista principal (sem waitlist_position) excluindo a
    # presença atual. Avulsos também contam para o limite de max_players.
    def compute_waitlist_position(exclude:)
      occupied = @weekly_session.attendances.active
        .where(status: :confirmed, waitlist_position: nil)
        .where.not(id: exclude.id)
        .count

      return nil if occupied < @weekly_session.max_players

      next_waitlist_position
    end

    def next_waitlist_position
      max = @weekly_session.attendances.active
        .where(status: :confirmed)
        .where.not(waitlist_position: nil)
        .maximum(:waitlist_position) || 0

      max + 1
    end
  end
end
