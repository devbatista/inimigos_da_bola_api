module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        def create
          user = User.active.find_by(email: sign_in_params[:email].to_s.downcase)

          unless user&.valid_password?(sign_in_params[:password].to_s)
            return render_error("UNAUTHORIZED", "Email ou senha inválidos.", :unauthorized)
          end

          access_token, payload = ::Auth::AccessToken.issue_for(user)
          refresh_token, refresh_token_record = RefreshToken.issue_for(user)

          render json: {
            access_token: access_token,
            access_token_expires_at: Time.at(payload.fetch("exp")).utc.iso8601,
            refresh_token: refresh_token,
            refresh_token_expires_at: refresh_token_record.expires_at.utc.iso8601,
            user: user_payload(user)
          }
        end

        private

        def sign_in_params
          params.fetch(:user, params).permit(:email, :password)
        end

        def user_payload(user)
          {
            id: user.id,
            email: user.email,
            name: user.name,
            phone: user.phone,
            admin: user.admin,
            player_type: user.player_type,
            skill_score: user.skill_score,
            goalkeeper: user.goalkeeper
          }
        end
      end
    end
  end
end
