module Notifications
  # Lembrete "Em 1h tem racha" enviado a todos. E agendado dinamicamente a
  # partir de RACHA_WEEKDAY/RACHA_TIME no initializer do Sidekiq, para disparar
  # ~1h antes do racha. A janela cobre pequenas variacoes de horario do cron.
  class RachaReminderJob < ApplicationJob
    REMINDER_WINDOW = 90.minutes

    queue_as :default

    def perform
      weekly_session = WeeklySession.active.scheduled
        .where(scheduled_at: Time.current..(Time.current + REMINDER_WINDOW))
        .order(:scheduled_at)
        .first

      return unless weekly_session

      Notifications::Push.new(
        audience: :all,
        title: "Racha hoje",
        body: "Em 1h tem racha. Já confirmou?",
        data: { weekly_session_id: weekly_session.id, type: "weekly_session_reminder" }
      ).call
    end
  end
end
