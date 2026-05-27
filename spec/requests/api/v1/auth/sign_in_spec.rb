require "rails_helper"

RSpec.describe "Auth sign in", type: :request do
  describe "POST /api/v1/auth/sign_in" do
    it "returns access and refresh tokens" do
      user = create(:user, password: "password123", password_confirmation: "password123")

      post "/api/v1/auth/sign_in", params: {
        email: user.email,
        password: "password123"
      }

      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      payload = Warden::JWTAuth::TokenDecoder.new.call(body.fetch("access_token"))

      expect(payload.fetch("sub")).to eq(user.id)
      expect(payload.fetch("scp")).to eq("user")
      expect(Time.at(payload.fetch("exp"))).to be_within(5.seconds).of(15.minutes.from_now)
      expect(body.fetch("access_token_expires_at")).to be_present
      expect(body.fetch("refresh_token")).to be_present
      expect(Time.iso8601(body.fetch("refresh_token_expires_at"))).to be_within(5.seconds).of(30.days.from_now)
      expect(RefreshToken.active.where(user: user)).to exist
    end

    it "does not serialize sensitive fields" do
      user = create(:user)

      post "/api/v1/auth/sign_in", params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("user")).to include(
        "id" => user.id,
        "email" => user.email,
        "name" => user.name
      )
      expect(response.body).not_to include("encrypted_password")
      expect(response.body).not_to include(user.encrypted_password)
    end

    it "rejects invalid credentials" do
      user = create(:user)

      post "/api/v1/auth/sign_in", params: {
        email: user.email,
        password: "wrong-password"
      }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "UNAUTHORIZED",
          "message" => "Email ou senha inválidos."
        }
      )
      expect(RefreshToken.count).to eq(0)
    end

    it "rejects soft deleted users" do
      user = create(:user)
      user.soft_delete!

      post "/api/v1/auth/sign_in", params: {
        email: user.email,
        password: "password123"
      }

      expect(response).to have_http_status(:unauthorized)
      expect(RefreshToken.count).to eq(0)
    end
  end
end
