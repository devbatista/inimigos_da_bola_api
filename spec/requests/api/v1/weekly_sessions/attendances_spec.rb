require "rails_helper"

RSpec.describe "Weekly session attendances", type: :request do
  let(:user) { create(:user) }
  let(:weekly_session) { create(:weekly_session, max_players: 2, scheduled_at: 2.days.from_now) }
  let(:headers) do
    access_token, = Auth::AccessToken.issue_for(user)
    { "Authorization" => "Bearer #{access_token}" }
  end

  describe "POST /api/v1/weekly_sessions/:id/attendances" do
    it "confirma presenca quando ha vaga" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "confirmed" },
        headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include(
        "user_id" => user.id,
        "weekly_session_id" => weekly_session.id,
        "kind" => "registered",
        "status" => "confirmed",
        "waitlist_position" => nil
      )
    end

    it "coloca presenca na waitlist quando lotado" do
      2.times { create(:attendance, weekly_session: weekly_session, status: :confirmed) }

      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "confirmed" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "status" => "confirmed",
        "waitlist_position" => 1
      )
    end

    it "incrementa waitlist_position para confirmacoes adicionais" do
      2.times { create(:attendance, weekly_session: weekly_session, status: :confirmed) }
      create(:attendance, weekly_session: weekly_session, status: :confirmed, waitlist_position: 1)

      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "confirmed" },
        headers: headers

      expect(response.parsed_body.fetch("waitlist_position")).to eq(2)
    end

    it "conta avulsos no limite de max_players" do
      create(:attendance, :guest, weekly_session: weekly_session, status: :confirmed)
      create(:attendance, weekly_session: weekly_session, status: :confirmed)

      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "confirmed" },
        headers: headers

      expect(response.parsed_body.fetch("waitlist_position")).to eq(1)
    end

    it "declina presenca e promove o primeiro da waitlist" do
      attendance = create(:attendance, user: user, weekly_session: weekly_session, status: :confirmed)
      promoted = create(:attendance, weekly_session: weekly_session, status: :confirmed, waitlist_position: 1)
      _later = create(:attendance, weekly_session: weekly_session, status: :confirmed, waitlist_position: 2)

      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "declined" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "status" => "declined",
        "waitlist_position" => nil
      )
      expect(attendance.reload.status).to eq("declined")
      expect(promoted.reload.waitlist_position).to be_nil
    end

    it "nao promove quem ja estava na waitlist ao declinar" do
      create(:attendance, weekly_session: weekly_session, status: :confirmed)
      create(:attendance, weekly_session: weekly_session, status: :confirmed)
      create(:attendance, user: user, weekly_session: weekly_session, status: :confirmed, waitlist_position: 1)
      next_waitlist = create(:attendance, weekly_session: weekly_session, status: :confirmed, waitlist_position: 2)

      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "declined" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(next_waitlist.reload.waitlist_position).to eq(2)
    end

    it "rejeita status invalido" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "maybe" },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "error" => { "code" => "VALIDATION_ERROR", "message" => "Status inválido." }
      )
    end

    it "bloqueia alteracoes apos scheduled_at" do
      past_session = create(:weekly_session, scheduled_at: 1.hour.ago, max_players: 5)

      post "/api/v1/weekly_sessions/#{past_session.id}/attendances",
        params: { status: "confirmed" },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "error" => { "code" => "ATTENDANCE_LOCKED", "message" => "A presença não pode mais ser alterada." }
      )
    end

    it "retorna 404 para sessao inexistente" do
      post "/api/v1/weekly_sessions/#{SecureRandom.uuid_v7}/attendances",
        params: { status: "confirmed" },
        headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "exige autenticacao" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "confirmed" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "e idempotente para confirmacao repetida" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "confirmed" },
        headers: headers
      first_id = response.parsed_body.fetch("id")

      post "/api/v1/weekly_sessions/#{weekly_session.id}/attendances",
        params: { status: "confirmed" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("id")).to eq(first_id)
      expect(weekly_session.attendances.active.where(user: user).count).to eq(1)
    end
  end
end
