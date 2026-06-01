require "sidekiq"

redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# Carrega o schedule do sidekiq-cron apenas no processo worker e quando o
# arquivo existir. Em test/development sem worker dedicado o cron fica inerte.
#
# config/schedule.yml e YAML puro (sem ERB / sem codigo Ruby).
Rails.application.config.after_initialize do
  next unless Sidekiq.server?

  schedule_file = Rails.root.join("config/schedule.yml")
  if File.exist?(schedule_file)
    schedule = YAML.safe_load(File.read(schedule_file), aliases: true) || {}
    Sidekiq::Cron::Job.load_from_hash!(schedule) if schedule.any?
  end

  # Lembrete "Em 1h tem racha": agendado dinamicamente a partir de
  # RACHA_WEEKDAY/RACHA_TIME (logica com ENV nao pode ficar no schedule.yml).
  weekday = WeeklySessions::CreateCurrent::WEEKDAYS[ENV.fetch("RACHA_WEEKDAY", "monday").downcase]
  hour, minute = ENV.fetch("RACHA_TIME", "20:00").split(":").map(&:to_i)

  if weekday && hour
    reminder_hour = (hour - 1) % 24
    reminder_weekday = hour.zero? ? (weekday - 1) % 7 : weekday

    Sidekiq::Cron::Job.create(
      name: "racha_reminder",
      cron: "#{minute} #{reminder_hour} * * #{reminder_weekday}",
      class: "Notifications::RachaReminderJob",
      queue: "default"
    )
  end
end
