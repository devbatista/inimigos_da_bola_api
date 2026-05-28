require "rails_helper"

RSpec.describe "Sync push", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:player) { create(:user) }
  let(:admin_headers) do
    access_token, = Auth::AccessToken.issue_for(admin)
    { "Authorization" => "Bearer #{access_token}", "Idempotency-Key" => SecureRandom.uuid_v7 }
  end
  let(:player_headers) do
    access_token, = Auth::AccessToken.issue_for(player)
    { "Authorization" => "Bearer #{access_token}", "Idempotency-Key" => SecureRandom.uuid_v7 }
  end

  describe "POST /api/v1/sync/:entity" do
    it "exige Idempotency-Key" do
      access_token, = Auth::AccessToken.issue_for(admin)

      post "/api/v1/sync/weekly_sessions",
        params: { op: "create", record: {} }.to_json,
        headers: { "Authorization" => "Bearer #{access_token}", "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("VALIDATION_ERROR")
      expect(response.parsed_body.dig("error", "message")).to include("Idempotency-Key")
    end

    it "bloqueia push de attendances" do
      post "/api/v1/sync/attendances",
        params: { op: "create", record: {} }.to_json,
        headers: admin_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("FORBIDDEN")
    end

    it "rejeita entidade desconhecida" do
      post "/api/v1/sync/widgets",
        params: { op: "create", record: {} }.to_json,
        headers: admin_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("VALIDATION_ERROR")
    end

    it "cria session_stat para admin" do
      weekly_session = create(:weekly_session)

      post "/api/v1/sync/session_stats",
        params: {
          op: "create",
          record: { weekly_session_id: weekly_session.id, user_id: player.id, goals: 2, assists: 1 }
        }.to_json,
        headers: admin_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "op" => "create",
        "entity" => "session_stats"
      )
      expect(response.parsed_body.dig("record", "goals")).to eq(2)
      expect(SessionStat.active.where(weekly_session: weekly_session, user: player).count).to eq(1)
    end

    it "bloqueia create de session_stat para usuario comum" do
      weekly_session = create(:weekly_session)

      post "/api/v1/sync/session_stats",
        params: {
          op: "create",
          record: { weekly_session_id: weekly_session.id, user_id: player.id, goals: 2, assists: 0 }
        }.to_json,
        headers: player_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:forbidden)
    end

    it "atualiza com lock otimista" do
      stat = create(:session_stat, goals: 1, assists: 0)

      post "/api/v1/sync/session_stats",
        params: { op: "update", record: { id: stat.id, version: stat.version, goals: 5 } }.to_json,
        headers: admin_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(stat.reload.goals).to eq(5)
      expect(stat.version).to eq(1)
    end

    it "retorna 409 em conflito de versao" do
      stat = create(:session_stat, goals: 1)

      post "/api/v1/sync/session_stats",
        params: { op: "update", record: { id: stat.id, version: 99, goals: 5 } }.to_json,
        headers: admin_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("SYNC_CONFLICT")
    end

    it "delete faz soft-delete" do
      stat = create(:session_stat)

      post "/api/v1/sync/session_stats",
        params: { op: "delete", record: { id: stat.id, version: stat.version } }.to_json,
        headers: admin_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(stat.reload.deleted_at).to be_present
    end

    it "e idempotente para a mesma mutation_id" do
      stat = create(:session_stat, goals: 1)
      mutation_id = SecureRandom.uuid_v7
      access_token, = Auth::AccessToken.issue_for(admin)
      headers = {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json",
        "Idempotency-Key" => mutation_id
      }

      post "/api/v1/sync/session_stats",
        params: { op: "update", record: { id: stat.id, version: stat.version, goals: 7 } }.to_json,
        headers: headers
      expect(response).to have_http_status(:ok)

      post "/api/v1/sync/session_stats",
        params: { op: "update", record: { id: stat.id, version: stat.reload.version, goals: 99 } }.to_json,
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("idempotent_replay")).to be(true)
      expect(stat.reload.goals).to eq(7)
    end

    it "bloqueia update de user de outro usuario" do
      other_user = create(:user, name: "Original")

      post "/api/v1/sync/users",
        params: { op: "update", record: { id: other_user.id, version: other_user.version, name: "Hackeado" } }.to_json,
        headers: player_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:forbidden)
      expect(other_user.reload.name).to eq("Original")
    end

    it "permite update do proprio user" do
      post "/api/v1/sync/users",
        params: { op: "update", record: { id: player.id, version: player.version, name: "Novo Nome" } }.to_json,
        headers: player_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(player.reload.name).to eq("Novo Nome")
    end

    it "exige autenticacao" do
      post "/api/v1/sync/weekly_sessions",
        params: { op: "create", record: {} }.to_json,
        headers: { "Content-Type" => "application/json", "Idempotency-Key" => SecureRandom.uuid_v7 }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
