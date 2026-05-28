require "rails_helper"

RSpec.describe "Auth refresh", type: :request do
  describe "POST /api/v1/auth/refresh" do
    it "rotates refresh token and returns a new access token" do
      user = create(:user)
      refresh_token, refresh_token_record = RefreshToken.issue_for(user)

      post "/api/v1/auth/refresh", params: { refresh_token: refresh_token }

      expect(response).to have_http_status(:ok)
      expect(refresh_token_record.reload).to be_revoked

      body = response.parsed_body
      payload = Warden::JWTAuth::TokenDecoder.new.call(body.fetch("access_token"))

      expect(payload.fetch("sub")).to eq(user.id)
      expect(Time.at(payload.fetch("exp"))).to be_within(5.seconds).of(15.minutes.from_now)
      expect(body.fetch("refresh_token")).to be_present
      expect(body.fetch("refresh_token")).not_to eq(refresh_token)
      expect(Time.iso8601(body.fetch("refresh_token_expires_at"))).to be_within(5.seconds).of(30.days.from_now)
      expect(RefreshToken.active.where(user: user).count).to eq(1)
    end

    it "rejects invalid refresh tokens" do
      post "/api/v1/auth/refresh", params: { refresh_token: "invalid" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "UNAUTHORIZED",
          "message" => "Refresh token inválido."
        }
      )
    end

    it "rejects revoked refresh tokens" do
      user = create(:user)
      refresh_token, refresh_token_record = RefreshToken.issue_for(user)
      refresh_token_record.revoke!

      post "/api/v1/auth/refresh", params: { refresh_token: refresh_token }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects refresh tokens from soft deleted users" do
      user = create(:user)
      refresh_token, = RefreshToken.issue_for(user)
      user.soft_delete!

      post "/api/v1/auth/refresh", params: { refresh_token: refresh_token }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
