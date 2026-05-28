require "rails_helper"

RSpec.describe "Auth sign out", type: :request do
  describe "DELETE /api/v1/auth/sign_out" do
    it "revokes the provided refresh token and current access tokens" do
      user = create(:user)
      access_token, payload = Auth::AccessToken.issue_for(user)
      refresh_token, refresh_token_record = RefreshToken.issue_for(user)
      original_jti = payload.fetch("jti")

      delete "/api/v1/auth/sign_out",
        params: { refresh_token: refresh_token },
        headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:no_content)
      expect(refresh_token_record.reload).to be_revoked
      expect(user.reload.jti).not_to eq(original_jti)
    end

    it "revokes all active refresh tokens when no refresh token is provided" do
      user = create(:user)
      access_token, = Auth::AccessToken.issue_for(user)
      first_token = create(:refresh_token, user: user)
      second_token = create(:refresh_token, user: user)

      delete "/api/v1/auth/sign_out",
        headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status(:no_content)
      expect(first_token.reload).to be_revoked
      expect(second_token.reload).to be_revoked
    end

    it "requires authentication" do
      delete "/api/v1/auth/sign_out"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
