require "rails_helper"

RSpec.describe "Auth token expired", type: :request do
  describe "endpoints autenticados" do
    it "retorna shape padronizado de token expirado" do
      user = create(:user)
      expired_token = travel_to(1.hour.ago) { Auth::AccessToken.issue_for(user).first }

      delete "/api/v1/auth/sign_out", headers: { "Authorization" => "Bearer #{expired_token}" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "token_expired",
          "message" => "Token expirado."
        }
      )
    end

    it "mantem code generico quando nao ha token" do
      delete "/api/v1/auth/sign_out"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "UNAUTHORIZED",
          "message" => "Você precisa estar autenticado."
        }
      )
    end

    it "mantem code generico quando o token e malformado" do
      delete "/api/v1/auth/sign_out", headers: { "Authorization" => "Bearer not-a-real-jwt" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "UNAUTHORIZED",
          "message" => "Você precisa estar autenticado."
        }
      )
    end
  end
end
