module Api
  module V1
    module Users
      class InvitationsController < ApplicationController
        before_action :authenticate_user!, only: :create

        def create
          authorize User, :invite?

          user = User.create!(invitation_create_attributes)
          raw_token = user.issue_invitation!
          AuthMailer.invitation(user, raw_token).deliver_now

          render json: {
            id: user.id,
            email: user.email,
            name: user.name,
            player_type: user.player_type,
            goalkeeper: user.goalkeeper,
            invitation_sent_at: user.invitation_sent_at.utc.iso8601
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render_error("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence, :unprocessable_entity)
        end

        def accept
          user = User.find_pending_invitation(accept_invitation_params[:invitation_token])

          return render_error("VALIDATION_ERROR", "Convite inválido.", :unprocessable_entity) unless user

          user.accept_invitation!(
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
          params.fetch(:user, params).permit(:email, :name)
        end

        def invitation_create_attributes
          invitation_create_params.to_h.symbolize_keys.merge(
            admin: false,
            player_type: "casual",
            goalkeeper: false,
            password: nil
          )
        end

        def accept_invitation_params
          params.fetch(:user, params).permit(
            :invitation_token,
            :password,
            :password_confirmation,
            :player_type,
            :goalkeeper
          )
        end
      end
    end
  end
end
