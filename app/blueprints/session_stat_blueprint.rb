class SessionStatBlueprint < Blueprinter::Base
  identifier :id

  fields :weekly_session_id,
    :user_id,
    :goals,
    :assists,
    :created_at,
    :updated_at,
    :deleted_at,
    :version
end
