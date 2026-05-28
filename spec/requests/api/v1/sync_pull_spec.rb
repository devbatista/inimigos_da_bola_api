require "rails_helper"

RSpec.describe "Sync pull", type: :request do
  let(:user) { create(:user) }
  let(:headers) do
    access_token, = Auth::AccessToken.issue_for(user)
    { "Authorization" => "Bearer #{access_token}" }
  end

  describe "GET /api/v1/sync" do
    it "retorna server_time e todas as entidades por padrao" do
      create(:weekly_session)

      get "/api/v1/sync", headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(Time.iso8601(body.fetch("server_time"))).to be_within(5.seconds).of(Time.current)
      expect(body.fetch("entities").keys).to match_array(%w[users weekly_sessions attendances session_stats])
    end

    it "filtra por since" do
      create(:weekly_session, created_at: 2.days.ago, updated_at: 2.days.ago)
      recent = create(:weekly_session)

      get "/api/v1/sync", params: { since: 1.day.ago.utc.iso8601 }, headers: headers

      ids = response.parsed_body.dig("entities", "weekly_sessions").map { |r| r["id"] }
      expect(ids).to eq([ recent.id ])
    end

    it "permite limitar com entities" do
      create(:weekly_session)

      get "/api/v1/sync", params: { entities: "weekly_sessions" }, headers: headers

      expect(response.parsed_body.fetch("entities").keys).to eq([ "weekly_sessions" ])
    end

    it "rejeita entidade desconhecida" do
      get "/api/v1/sync", params: { entities: "secrets" }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "error" => { "code" => "VALIDATION_ERROR", "message" => "Entidade desconhecida: secrets." }
      )
    end

    it "rejeita since malformado" do
      get "/api/v1/sync", params: { since: "not-a-date" }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("VALIDATION_ERROR")
    end

    it "inclui tombstones (soft-deleted) com deleted_at populado" do
      session = create(:weekly_session)
      session.soft_delete!

      get "/api/v1/sync", headers: headers

      records = response.parsed_body.dig("entities", "weekly_sessions")
      tombstone = records.find { |r| r["id"] == session.id }
      expect(tombstone).to be_present
      expect(tombstone["deleted_at"]).to be_present
    end

    it "nao expoe encrypted_password nem skill_ratings individuais" do
      get "/api/v1/sync", headers: headers

      body = response.body
      expect(body).not_to include("encrypted_password")
      expect(body).not_to include(user.encrypted_password)
      expect(body).not_to include("jti")
      expect(body).not_to include("fcm_token")
      expect(response.parsed_body.fetch("entities").keys).not_to include("skill_ratings")
    end

    it "exige autenticacao" do
      get "/api/v1/sync"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
