module Api
  module V1
    module Users
      class MeController < ApplicationController
        before_action :authenticate_user!

        def show
          authorize current_user, :show?

          render json: UserBlueprint.render_as_hash(current_user)
        end

        def update_fcm_token
          authorize current_user, :update?

          fcm_token = fcm_token_params[:fcm_token].to_s.strip

          if fcm_token.blank?
            return render_error("VALIDATION_ERROR", "Token FCM é obrigatório.", :unprocessable_entity)
          end

          current_user.update!(fcm_token: fcm_token)
          head :no_content
        end

        private

        def fcm_token_params
          params.permit(:fcm_token)
        end
      end
    end
  end
end
