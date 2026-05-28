module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        before_action :authenticate_user!, only: :destroy

        def create
          user = User.active.find_by(email: sign_in_params[:email].to_s.downcase)

          unless user&.valid_password?(sign_in_params[:password].to_s)
            return render_error("UNAUTHORIZED", "Email ou senha inválidos.", :unauthorized)
          end

          render json: ::Auth::TokenResponse.for(user)
        end

        def destroy
          revoke_refresh_tokens
          current_user.update!(jti: SecureRandom.uuid)

          head :no_content
        end

        def refresh
          refresh_token_record = RefreshToken.active
            .joins(:user)
            .merge(User.active)
            .find_by(token_digest: RefreshToken.digest(refresh_params[:refresh_token].to_s))

          return render_error("UNAUTHORIZED", "Refresh token inválido.", :unauthorized) unless refresh_token_record

          user = refresh_token_record.user
          refresh_token_record.revoke!

          render json: ::Auth::TokenResponse.for(user)
        end

        private

        def sign_in_params
          params.fetch(:user, params).permit(:email, :password)
        end

        def sign_out_params
          params.permit(:refresh_token)
        end

        def refresh_params
          params.permit(:refresh_token)
        end

        def revoke_refresh_tokens
          if sign_out_params[:refresh_token].present?
            RefreshToken.active
              .where(user: current_user, token_digest: RefreshToken.digest(sign_out_params[:refresh_token]))
              .find_each(&:revoke!)
          else
            current_user.refresh_tokens.active.find_each(&:revoke!)
          end
        end
      end
    end
  end
end
