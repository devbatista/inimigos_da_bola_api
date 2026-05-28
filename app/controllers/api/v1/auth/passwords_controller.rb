module Api
  module V1
    module Auth
      class PasswordsController < ApplicationController
        def create
          user = User.active.find_by(email: password_create_params[:email].to_s.downcase)
          AuthMailer.reset_password(user, user.send(:set_reset_password_token)).deliver_now if user

          head :no_content
        end

        def update
          user = User.reset_password_by_token(password_update_params)

          if user.errors.empty? && user.deleted_at.blank?
            head :no_content
          else
            render_error("VALIDATION_ERROR", "Token ou senha inválidos.", :unprocessable_entity)
          end
        end

        private

        def password_create_params
          params.fetch(:user, params).permit(:email)
        end

        def password_update_params
          params.fetch(:user, params).permit(:reset_password_token, :password, :password_confirmation)
        end
      end
    end
  end
end
