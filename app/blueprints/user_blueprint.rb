class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :name, :phone, :admin, :player_type, :skill_score, :goalkeeper

  view :sync do
    fields :created_at, :updated_at, :deleted_at, :version
  end
end
