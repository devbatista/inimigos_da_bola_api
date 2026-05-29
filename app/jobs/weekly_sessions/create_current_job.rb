module WeeklySessions
  class CreateCurrentJob < ApplicationJob
    queue_as :default

    def perform
      result = WeeklySessions::CreateCurrent.new.call
      return result unless result.success?

      weekly_session = result.data
      # Apenas dispara notificacao quando a sessao foi recem-criada, para
      # manter a semana idempotente caso o job rode mais de uma vez.
      broadcast_session_open(weekly_session) if weekly_session.previously_new_record?

      result
    end

    private

    def broadcast_session_open(weekly_session)
      Notifications::Push.new(
        audience: :all,
        title: "Racha aberto",
        body: "O racha de hoje esta aberto. Voce vai?",
        data: { weekly_session_id: weekly_session.id, type: "weekly_session_open" }
      ).call
    end
  end
end
