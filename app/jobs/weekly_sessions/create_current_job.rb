module WeeklySessions
  class CreateCurrentJob < ApplicationJob
    queue_as :default

    def perform
      result = WeeklySessions::CreateCurrent.new.call
      return result unless result.success?

      weekly_session = result.data
      # Apenas dispara notificação quando a sessão foi recém-criada, para
      # manter a semana idempotente caso o job rode mais de uma vez.
      broadcast_session_open(weekly_session) if weekly_session.previously_new_record?

      result
    end

    private

    def broadcast_session_open(weekly_session)
      Notifications::Push.new(
        audience: :all,
        title: "Racha aberto",
        body: "O racha de #{racha_label(weekly_session.scheduled_at)} está aberto. Você vai?",
        data: { weekly_session_id: weekly_session.id, type: "weekly_session_open" }
      ).call
    end

    # Ex.: "segunda (02/06)".
    def racha_label(scheduled_at)
      weekdays = %w[domingo segunda terca quarta quinta sexta sabado]
      date = scheduled_at.in_time_zone
      "#{weekdays[date.wday]} (#{date.strftime('%d/%m')})"
    end
  end
end
