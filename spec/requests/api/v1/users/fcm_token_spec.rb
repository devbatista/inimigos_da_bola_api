require "rails_helper"

RSpec.describe "Users FCM token", type: :request do
  let(:user) { create(:user) }
  let(:headers) do
    access_token, = Auth::AccessToken.issue_for(user)
    { "Authorization" => "Bearer #{access_token}" }
  end

  describe "POST /api/v1/users/me/fcm_token" do
    it "salva o token do usuario logado" do
      post "/api/v1/users/me/fcm_token",
        params: { fcm_token: "token-abc-123" },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.reload.fcm_token).to eq("token-abc-123")
    end

    it "atualiza um token ja existente" do
      user.update!(fcm_token: "antigo")

      post "/api/v1/users/me/fcm_token",
        params: { fcm_token: "novo" },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.reload.fcm_token).to eq("novo")
    end

    it "rejeita token em branco" do
      post "/api/v1/users/me/fcm_token",
        params: { fcm_token: "  " },
        headers: headers,
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("VALIDATION_ERROR")
    end

    it "exige autenticacao" do
      post "/api/v1/users/me/fcm_token", params: { fcm_token: "token" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
