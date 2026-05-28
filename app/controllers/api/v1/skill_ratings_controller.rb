module Api
  module V1
    class SkillRatingsController < ApplicationController
      before_action :authenticate_user!

      def create
        authorize SkillRating, :create?

        result = ::SkillRatings::Upsert.new(
          evaluator: current_user,
          evaluated_user_id: skill_rating_params[:evaluated_user_id],
          score: skill_rating_params[:score]
        ).call

        if result.success?
          render json: SkillRatingBlueprint.render_as_hash(result.data), status: :created
        else
          render_error(result.code, result.message, :unprocessable_entity)
        end
      end

      private

      def skill_rating_params
        params.permit(:evaluated_user_id, :score)
      end
    end
  end
end
