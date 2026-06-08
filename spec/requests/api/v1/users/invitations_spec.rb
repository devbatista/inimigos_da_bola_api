require "rails_helper"

RSpec.describe "User invitations", type: :request do
  describe "POST /api/v1/users/invitations" do
    it "allows admins to create shareable invitation links" do
      admin = create(:user, :admin)
      access_token, = Auth::AccessToken.issue_for(admin)

      expect {
        post "/api/v1/users/invitations",
          params: { name: "Rafael Batista", player_type: "monthly", goalkeeper: true },
          headers: { "Authorization" => "Bearer #{access_token}" }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)

      invited_user = User.order(:created_at).last
      body = response.parsed_body
      raw_token = body.fetch("invitation_token")

      expect(invited_user.email).to be_nil
      expect(invited_user.name).to eq("Rafael Batista")
      expect(invited_user).not_to be_admin
      expect(invited_user).to be_monthly
      expect(invited_user).to be_goalkeeper
      expect(invited_user.encrypted_password).to eq("")
      expect(invited_user.valid_password?("password123")).to be(false)
      expect(invited_user.invitation_token).to be_present
      expect(invited_user.invitation_token).not_to eq(raw_token)
      expect(invited_user.invitation_sent_at).to be_present
      expect(invited_user.invitation_expires_at).to be_within(5.seconds).of(7.days.from_now)
      expect(invited_user.invitation_accepted_at).to be_nil
      expect(body).to include(
        "id" => invited_user.id,
        "name" => invited_user.name,
        "player_type" => "monthly",
        "goalkeeper" => true,
        "invitation_token" => raw_token,
        "invitation_url" => "inimigosdabola://accept-invitation?invitation_token=#{raw_token}"
      )
      expect(Time.iso8601(body.fetch("expires_at"))).to be_within(5.seconds).of(7.days.from_now)
      expect(body).not_to include("email")
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "defaults player type and goalkeeper when omitted" do
      admin = create(:user, :admin)
      access_token, = Auth::AccessToken.issue_for(admin)

      post "/api/v1/users/invitations",
        params: { name: "Guest Player" },
        headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "player_type" => "casual",
        "goalkeeper" => false
      )
    end

    it "blocks non-admin users" do
      player = create(:user)
      access_token, = Auth::AccessToken.issue_for(player)

      expect {
        post "/api/v1/users/invitations",
          params: { name: "Guest Player" },
          headers: { "Authorization" => "Bearer #{access_token}" }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/v1/users/invitations", params: { name: "Guest Player" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/users/accept_invitation" do
    it "accepts an invitation and emits tokens" do
      user = User.create!(name: "Guest Player", player_type: :casual)
      raw_token = user.issue_invitation!

      post "/api/v1/users/accept_invitation", params: {
        token: raw_token,
        name: "Rafael Batista",
        email: "RAFAEL@example.com",
        password: "password123",
        player_type: "monthly",
        goalkeeper: true
      }

      expect(response).to have_http_status(:ok)

      user.reload
      body = response.parsed_body
      payload = Warden::JWTAuth::TokenDecoder.new.call(body.fetch("access_token"))

      expect(payload.fetch("sub")).to eq(user.id)
      expect(body.fetch("refresh_token")).to be_present
      expect(user.email).to eq("rafael@example.com")
      expect(user.name).to eq("Rafael Batista")
      expect(user).to be_valid_password("password123")
      expect(user).to be_monthly
      expect(user).to be_goalkeeper
      expect(user.invitation_token).to be_nil
      expect(user.invitation_expires_at).to be_nil
      expect(user.invitation_accepted_at).to be_present
      expect(RefreshToken.active.where(user: user)).to exist
    end

    it "rejects invalid, expired, or already accepted invitations" do
      post "/api/v1/users/accept_invitation", params: {
        token: "invalid",
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "invalid_invitation",
          "message" => "Convite inválido ou expirado."
        }
      )
    end

    it "rejects expired invitations" do
      user = User.create!(name: "Guest Player", player_type: :casual)
      raw_token = user.issue_invitation!
      user.update!(invitation_expires_at: 1.second.ago)

      post "/api/v1/users/accept_invitation", params: {
        token: raw_token,
        email: "guest@example.com",
        password: "password123"
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_invitation")
    end

    it "rejects already accepted invitations" do
      user = User.create!(name: "Guest Player", player_type: :casual)
      raw_token = user.issue_invitation!
      user.accept_invitation!(
        email: "guest@example.com",
        password: "password123",
        password_confirmation: "password123",
        player_type: "casual",
        goalkeeper: false
      )

      post "/api/v1/users/accept_invitation", params: {
        token: raw_token,
        email: "other@example.com",
        password: "password123"
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_invitation")
    end

    it "rejects password confirmation mismatch" do
      user = User.create!(name: "Guest Player", player_type: :casual)
      raw_token = user.issue_invitation!

      post "/api/v1/users/accept_invitation", params: {
        token: raw_token,
        email: "guest@example.com",
        password: "password123",
        password_confirmation: "different"
      }

      expect(response).to have_http_status(422)
      expect(user.reload.invitation_accepted_at).to be_nil
      expect(user.encrypted_password).to eq("")
    end
  end
end
