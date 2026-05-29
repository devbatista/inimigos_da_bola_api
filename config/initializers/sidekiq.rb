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
  next unless File.exist?(schedule_file)

  schedule = YAML.safe_load(File.read(schedule_file), aliases: true) || {}
  Sidekiq::Cron::Job.load_from_hash!(schedule) if schedule.any?
end
