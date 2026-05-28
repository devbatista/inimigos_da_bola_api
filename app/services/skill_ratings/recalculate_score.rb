module SkillRatings
  class RecalculateScore
    def initialize(user:)
      @user = user
    end

    def call
      average = SkillRating.active.where(evaluated_user_id: @user.id).average(:score)
      score = average ? average.to_d.round(2) : nil
      @user.update!(skill_score: score)

      ServiceResult.success(@user.skill_score)
    end
  end
end
