require "rails_helper"

RSpec.describe "Auth password", type: :request do
  describe "POST /api/v1/auth/password" do
    it "sends reset instructions for active users" do
      user = create(:user)

      expect {
        post "/api/v1/auth/password", params: { email: user.email }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to have_http_status(:no_content)
      expect(user.reload.reset_password_token).to be_present
    end

    it "does not reveal unknown emails" do
      expect {
        post "/api/v1/auth/password", params: { email: "unknown@example.com" }
      }.not_to change { ActionMailer::Base.deliveries.count }

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "PUT /api/v1/auth/password" do
    it "updates password with a valid reset token" do
      user = create(:user, password: "old-password", password_confirmation: "old-password")
      raw_token = user.send(:set_reset_password_token)

      put "/api/v1/auth/password", params: {
        reset_password_token: raw_token,
        password: "new-password",
        password_confirmation: "new-password"
      }

      expect(response).to have_http_status(:no_content)
      expect(user.reload).to be_valid_password("new-password")
      expect(user.encrypted_password).not_to include("new-password")
    end

    it "rejects invalid reset token" do
      put "/api/v1/auth/password", params: {
        reset_password_token: "invalid",
        password: "new-password",
        password_confirmation: "new-password"
      }

      expect(response).to have_http_status(422)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "VALIDATION_ERROR",
          "message" => "Token ou senha inválidos."
        }
      )
    end

    it "rejects password confirmation mismatch" do
      user = create(:user)
      raw_token = user.send(:set_reset_password_token)

      put "/api/v1/auth/password", params: {
        reset_password_token: raw_token,
        password: "new-password",
        password_confirmation: "different-password"
      }

      expect(response).to have_http_status(422)
      expect(user.reload).to be_valid_password("password123")
    end
  end
end
