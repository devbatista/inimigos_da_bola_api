require "rails_helper"

RSpec.describe "User invitations", type: :request do
  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /api/v1/users/invitations" do
    it "allows admins to invite users" do
      admin = create(:user, :admin)
      access_token, = Auth::AccessToken.issue_for(admin)

      expect {
        post "/api/v1/users/invitations",
          params: { email: "guest@example.com", name: "Guest Player" },
          headers: { "Authorization" => "Bearer #{access_token}" }
      }.to change(User, :count).by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to have_http_status(:created)

      invited_user = User.find_by!(email: "guest@example.com")
      expect(invited_user.name).to eq("Guest Player")
      expect(invited_user).not_to be_admin
      expect(invited_user).to be_casual
      expect(invited_user).not_to be_goalkeeper
      expect(invited_user.encrypted_password).to eq("")
      expect(invited_user.valid_password?("password123")).to be(false)
      expect(invited_user.invitation_token).to be_present
      expect(invited_user.invitation_sent_at).to be_present
      expect(invited_user.invitation_accepted_at).to be_nil
      expect(response.parsed_body).to include(
        "id" => invited_user.id,
        "email" => invited_user.email,
        "name" => invited_user.name,
        "player_type" => "casual",
        "goalkeeper" => false
      )
      expect(response.body).not_to include("invitation_token")
      expect(ActionMailer::Base.deliveries.last.body.encoded).to include("Guest Player")
    end

    it "blocks non-admin users" do
      player = create(:user)
      access_token, = Auth::AccessToken.issue_for(player)

      expect {
        post "/api/v1/users/invitations",
          params: { email: "guest@example.com", name: "Guest Player" },
          headers: { "Authorization" => "Bearer #{access_token}" }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/v1/users/invitations", params: { email: "guest@example.com", name: "Guest Player" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/users/accept_invitation" do
    it "accepts an invitation and emits tokens" do
      user = User.create!(email: "guest@example.com", name: "Guest Player", player_type: :casual)
      raw_token = user.issue_invitation!

      post "/api/v1/users/accept_invitation", params: {
        invitation_token: raw_token,
        password: "password123",
        password_confirmation: "password123",
        player_type: "monthly",
        goalkeeper: true
      }

      expect(response).to have_http_status(:ok)

      user.reload
      body = response.parsed_body
      payload = Warden::JWTAuth::TokenDecoder.new.call(body.fetch("access_token"))

      expect(payload.fetch("sub")).to eq(user.id)
      expect(body.fetch("refresh_token")).to be_present
      expect(user).to be_valid_password("password123")
      expect(user).to be_monthly
      expect(user).to be_goalkeeper
      expect(user.invitation_token).to be_nil
      expect(user.invitation_accepted_at).to be_present
      expect(RefreshToken.active.where(user: user)).to exist
    end

    it "rejects invalid invitations" do
      post "/api/v1/users/accept_invitation", params: {
        invitation_token: "invalid",
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "VALIDATION_ERROR",
          "message" => "Convite inválido."
        }
      )
    end

    it "rejects password confirmation mismatch" do
      user = User.create!(email: "guest@example.com", name: "Guest Player", player_type: :casual)
      raw_token = user.issue_invitation!

      post "/api/v1/users/accept_invitation", params: {
        invitation_token: raw_token,
        password: "password123",
        password_confirmation: "different"
      }

      expect(response).to have_http_status(422)
      expect(user.reload.invitation_accepted_at).to be_nil
      expect(user.encrypted_password).to eq("")
    end
  end
end
