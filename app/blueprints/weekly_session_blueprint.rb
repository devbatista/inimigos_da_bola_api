class WeeklySessionBlueprint < Blueprinter::Base
  identifier :id

  fields :scheduled_at, :max_players, :status, :created_at, :updated_at, :deleted_at, :version
end
