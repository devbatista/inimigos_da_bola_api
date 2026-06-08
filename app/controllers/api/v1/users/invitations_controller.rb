module Api
  module V1
    module Users
      class InvitationsController < ApplicationController
        before_action :authenticate_user!, only: :create

        def create
          authorize User, :invite?

          user = User.create!(invitation_create_attributes)
          raw_token = user.issue_invitation!

          render json: {
            id: user.id,
            name: user.name,
            player_type: user.player_type,
            goalkeeper: user.goalkeeper,
            invitation_token: raw_token,
            invitation_url: invitation_url(raw_token),
            expires_at: user.invitation_expires_at.utc.iso8601
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_error("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence, :unprocessable_entity)
        end

        def accept
          user = User.find_pending_invitation(invitation_token_param)

          return invalid_invitation_error unless user

          user.accept_invitation!(
            name: accept_invitation_params[:name],
            email: accept_invitation_params[:email],
            password: accept_invitation_params[:password],
            password_confirmation: accept_invitation_params[:password_confirmation],
            player_type: accept_invitation_params[:player_type],
            goalkeeper: accept_invitation_params[:goalkeeper]
          )

          render json: ::Auth::TokenResponse.for(user)
        rescue ActiveRecord::RecordInvalid => e
          render_error("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence, :unprocessable_entity)
        end

        private

        def invitation_create_params
          params.fetch(:user, params).permit(:name, :player_type, :goalkeeper)
        end

        def invitation_create_attributes
          invitation_create_params.to_h.symbolize_keys.merge(
            admin: false,
            password: nil
          ).reverse_merge(player_type: "casual", goalkeeper: false)
        end

        def accept_invitation_params
          params.fetch(:user, params).permit(
            :token,
            :invitation_token,
            :name,
            :email,
            :password,
            :password_confirmation,
            :player_type,
            :goalkeeper
          )
        end

        def invitation_token_param
          accept_invitation_params[:invitation_token].presence || accept_invitation_params[:token]
        end

        def invitation_url(raw_token)
          base_url = ENV.fetch("INVITATION_DEEP_LINK_BASE", "inimigosdabola://accept-invitation")
          "#{base_url}?invitation_token=#{raw_token}"
        end

        def invalid_invitation_error
          render_error("invalid_invitation", "Convite inválido ou expirado.", :unprocessable_entity)
        end
      end
    end
  end
end
