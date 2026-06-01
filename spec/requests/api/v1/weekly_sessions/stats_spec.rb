require "rails_helper"

RSpec.describe "Weekly session stats", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:player) { create(:user) }
  let(:weekly_session) { create(:weekly_session, scheduled_at: 1.hour.ago) }

  before { create(:attendance, weekly_session: weekly_session, user: player, status: :confirmed) }

  def auth_headers_for(user)
    access_token, = Auth::AccessToken.issue_for(user)
    { "Authorization" => "Bearer #{access_token}" }
  end

  describe "POST /api/v1/weekly_sessions/:id/stats" do
    it "permite admin registrar stats em lote" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/stats",
        params: { stats: [ { user_id: player.id, goals: 3, assists: 1 } ] },
        headers: auth_headers_for(admin),
        as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body.first).to include(
        "user_id" => player.id,
        "goals" => 3,
        "assists" => 1
      )
    end

    it "bloqueia usuario comum" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/stats",
        params: { stats: [ { user_id: player.id, goals: 1, assists: 0 } ] },
        headers: auth_headers_for(player),
        as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "bloqueia jogador sem presenca registrada" do
      outsider = create(:user)

      post "/api/v1/weekly_sessions/#{weekly_session.id}/stats",
        params: { stats: [ { user_id: outsider.id, goals: 1, assists: 0 } ] },
        headers: auth_headers_for(admin),
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("STATS_USER_NOT_IN_SESSION")
    end

    it "bloqueia edicao depois de 24h do racha" do
      weekly_session.update_column(:scheduled_at, 25.hours.ago)

      post "/api/v1/weekly_sessions/#{weekly_session.id}/stats",
        params: { stats: [ { user_id: player.id, goals: 1, assists: 0 } ] },
        headers: auth_headers_for(admin),
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("STATS_LOCKED")
    end

    it "exige autenticacao" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/stats",
        params: { stats: [ { user_id: player.id, goals: 1, assists: 0 } ] },
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
