require "rails_helper"

RSpec.describe "Weekly session guest attendances", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:player) { create(:user) }
  let(:weekly_session) { create(:weekly_session, max_players: 2, scheduled_at: 2.days.from_now) }
  let(:admin_headers) do
    access_token, = Auth::AccessToken.issue_for(admin)
    { "Authorization" => "Bearer #{access_token}" }
  end
  let(:player_headers) do
    access_token, = Auth::AccessToken.issue_for(player)
    { "Authorization" => "Bearer #{access_token}" }
  end

  describe "POST /api/v1/weekly_sessions/:id/guest_attendances" do
    it "admin cria avulso quando ha vaga" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances",
        params: { guest_name: "Visitante" },
        headers: admin_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "weekly_session_id" => weekly_session.id,
        "kind" => "guest",
        "guest_name" => "Visitante",
        "created_by_admin_id" => admin.id,
        "status" => "confirmed",
        "user_id" => nil,
        "waitlist_position" => nil
      )
    end

    it "avulso vai para waitlist quando lotado" do
      2.times { create(:attendance, weekly_session: weekly_session, status: :confirmed) }

      post "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances",
        params: { guest_name: "Visitante" },
        headers: admin_headers

      expect(response.parsed_body.fetch("waitlist_position")).to eq(1)
    end

    it "bloqueia usuario comum" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances",
        params: { guest_name: "Visitante" },
        headers: player_headers

      expect(response).to have_http_status(:forbidden)
      expect(weekly_session.attendances.guest.count).to eq(0)
    end

    it "exige guest_name" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances",
        params: { guest_name: "" },
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "error" => { "code" => "VALIDATION_ERROR", "message" => "Nome do avulso é obrigatório." }
      )
    end

    it "bloqueia apos scheduled_at" do
      past_session = create(:weekly_session, scheduled_at: 1.hour.ago)

      post "/api/v1/weekly_sessions/#{past_session.id}/guest_attendances",
        params: { guest_name: "Visitante" },
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("ATTENDANCE_LOCKED")
    end

    it "exige autenticacao" do
      post "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances",
        params: { guest_name: "Visitante" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/weekly_sessions/:id/guest_attendances/:attendance_id" do
    let!(:guest) { create(:attendance, :guest, weekly_session: weekly_session, status: :confirmed, created_by_admin: admin) }

    it "admin remove avulso e promove waitlist" do
      next_in_line = create(:attendance, weekly_session: weekly_session, status: :confirmed, waitlist_position: 1)

      delete "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances/#{guest.id}",
        headers: admin_headers

      expect(response).to have_http_status(:no_content)
      expect(guest.reload.deleted_at).to be_present
      expect(next_in_line.reload.waitlist_position).to be_nil
    end

    it "bloqueia usuario comum" do
      delete "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances/#{guest.id}",
        headers: player_headers

      expect(response).to have_http_status(:forbidden)
      expect(guest.reload.deleted_at).to be_nil
    end

    it "404 quando attendance nao pertence a sessao" do
      other_session = create(:weekly_session, scheduled_at: 3.days.from_now)
      other_guest = create(:attendance, :guest, weekly_session: other_session, status: :confirmed, created_by_admin: admin)

      delete "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances/#{other_guest.id}",
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end

    it "404 quando attendance e registered (nao guest)" do
      registered = create(:attendance, weekly_session: weekly_session, status: :confirmed)

      delete "/api/v1/weekly_sessions/#{weekly_session.id}/guest_attendances/#{registered.id}",
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end

    it "bloqueia apos scheduled_at" do
      past_session = create(:weekly_session, scheduled_at: 1.hour.ago)
      past_guest = create(:attendance, :guest, weekly_session: past_session, status: :confirmed, created_by_admin: admin)

      delete "/api/v1/weekly_sessions/#{past_session.id}/guest_attendances/#{past_guest.id}",
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("ATTENDANCE_LOCKED")
    end
  end
end
