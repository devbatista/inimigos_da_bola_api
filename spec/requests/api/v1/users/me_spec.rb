require "rails_helper"

RSpec.describe "Users me", type: :request do
  describe "GET /api/v1/users/me" do
    it "retorna o usuario autenticado" do
      user = create(:user, skill_score: 75.5)
      access_token, = Auth::AccessToken.issue_for(user)

      get "/api/v1/users/me", headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "id" => user.id,
        "email" => user.email,
        "name" => user.name,
        "phone" => user.phone,
        "admin" => user.admin,
        "player_type" => user.player_type,
        "skill_score" => "75.5",
        "goalkeeper" => user.goalkeeper
      )
    end

    it "nao expoe campos sensiveis" do
      user = create(:user)
      access_token, = Auth::AccessToken.issue_for(user)

      get "/api/v1/users/me", headers: { "Authorization" => "Bearer #{access_token}" }

      body = response.body
      expect(body).not_to include("encrypted_password")
      expect(body).not_to include(user.encrypted_password)
      expect(body).not_to include("jti")
      expect(body).not_to include("fcm_token")
      expect(body).not_to include("reset_password_token")
      expect(body).not_to include("invitation_token")
    end

    it "exige autenticacao" do
      get "/api/v1/users/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
