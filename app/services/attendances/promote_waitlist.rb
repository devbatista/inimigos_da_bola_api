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

      notify_promoted(next_in_line)

      ServiceResult.success(next_in_line)
    end

    private

    # Avisa o jogador promovido. Avulsos (sem user_id) não recebem push, mas o
    # sync silencioso e disparado para atualizar a lista em todos os apps.
    def notify_promoted(attendance)
      if attendance.user_id
        Notifications::PushJob.perform_later(
          audience: "user",
          user_id: attendance.user_id,
          title: "Abriu vaga!",
          body: "Você está confirmado para hoje.",
          data: { weekly_session_id: @weekly_session.id, type: "waitlist_promoted" }
        )
      end

      Notifications::PushJob.perform_later(
        audience: "all",
        data: { weekly_session_id: @weekly_session.id, type: "sync" }
      )
    end
  end
end
