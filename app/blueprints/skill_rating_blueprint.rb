# Atenção: usar apenas para o próprio avaliador. Não expor notas individuais
# de outros usuários (privacidade de skill_ratings).
class SkillRatingBlueprint < Blueprinter::Base
  identifier :id

  fields :evaluator_user_id,
    :evaluated_user_id,
    :score,
    :created_at,
    :updated_at,
    :deleted_at,
    :version
end
