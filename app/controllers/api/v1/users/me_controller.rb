module Api
  module V1
    module Users
      class MeController < ApplicationController
        before_action :authenticate_user!

        def show
          authorize current_user, :show?

          render json: UserBlueprint.render_as_hash(current_user)
        end
      end
    end
  end
end
