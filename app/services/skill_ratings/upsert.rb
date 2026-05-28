module SkillRatings
  class Upsert
    REEVALUATION_WINDOW = 1.month

    def initialize(evaluator:, evaluated_user_id:, score:)
      @evaluator = evaluator
      @evaluated_user_id = evaluated_user_id
      @score = score
    end

    def call
      return ServiceResult.failure("SKILL_RATING_SELF_NOT_ALLOWED", "Você não pode avaliar a si mesmo.") if self_rating?

      evaluated_user = User.active.find_by(id: @evaluated_user_id)
      return ServiceResult.failure("VALIDATION_ERROR", "Usuário avaliado não encontrado.") unless evaluated_user

      rating = SkillRating.active.find_or_initialize_by(
        evaluator_user_id: @evaluator.id,
        evaluated_user_id: evaluated_user.id
      )

      if rating.persisted? && rating.updated_at > REEVALUATION_WINDOW.ago
        return ServiceResult.failure("SKILL_RATING_TOO_SOON", "Você só pode reavaliar este jogador após 1 mês.")
      end

      rating.score = @score
      rating.save!

      SkillRatings::RecalculateScore.new(user: evaluated_user).call

      ServiceResult.success(rating)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence)
    end

    private

    def self_rating?
      @evaluator.id == @evaluated_user_id
    end
  end
end
