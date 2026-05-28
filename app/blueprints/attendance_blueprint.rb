class AttendanceBlueprint < Blueprinter::Base
  identifier :id

  fields :weekly_session_id,
    :user_id,
    :created_by_admin_id,
    :kind,
    :guest_name,
    :status,
    :waitlist_position,
    :created_at,
    :updated_at,
    :deleted_at,
    :version
end
