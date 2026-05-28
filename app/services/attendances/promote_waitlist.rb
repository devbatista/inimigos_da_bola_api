module Attendances
  class PromoteWaitlist
    def initialize(weekly_session:)
      @weekly_session = weekly_session
    end

    def call
      next_in_line = @weekly_session.attendances.active
        .where(status: :confirmed)
        .where.not(waitlist_position: nil)
        .order(:waitlist_position)
        .first

      return ServiceResult.success(nil) unless next_in_line

      next_in_line.update!(waitlist_position: nil)
      ServiceResult.success(next_in_line)
    end
  end
end
