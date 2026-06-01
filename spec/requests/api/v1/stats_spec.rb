require "rails_helper"

RSpec.describe "Stats leaderboard", type: :request do
  let(:viewer) { create(:user) }
  let(:headers) do
    access_token, = Auth::AccessToken.issue_for(viewer)
    { "Authorization" => "Bearer #{access_token}" }
  end

  let(:artilheiro) { create(:user, name: "Artilheiro") }
  let(:garcom) { create(:user, name: "Garçom") }

  describe "GET /api/v1/stats/leaderboard" do
    it "agrega stats do mes e ordena por gols" do
      session_a = create(:weekly_session, scheduled_at: Time.current.beginning_of_month + 2.days)
      session_b = create(:weekly_session, scheduled_at: Time.current.beginning_of_month + 9.days)

      create(:session_stat, weekly_session: session_a, user: artilheiro, goals: 3, assists: 0)
      create(:session_stat, weekly_session: session_b, user: artilheiro, goals: 2, assists: 1)
      create(:session_stat, weekly_session: session_a, user: garcom, goals: 1, assists: 4)

      get "/api/v1/stats/leaderboard", params: { period: "month" }, headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["period"]).to eq("month")
      expect(body["leaderboard"].size).to eq(2)
      expect(body["leaderboard"].first).to include(
        "user_id" => artilheiro.id,
        "name" => "Artilheiro",
        "goals" => 5,
        "assists" => 1,
        "games" => 2
      )
    end

    it "ignora stats fora do periodo mensal" do
      last_month = create(:weekly_session, scheduled_at: 1.month.ago.beginning_of_month + 1.day)
      this_month = create(:weekly_session, scheduled_at: Time.current.beginning_of_month + 1.day)

      create(:session_stat, weekly_session: last_month, user: artilheiro, goals: 9, assists: 0)
      create(:session_stat, weekly_session: this_month, user: garcom, goals: 1, assists: 0)

      get "/api/v1/stats/leaderboard", params: { period: "month" }, headers: headers

      body = response.parsed_body
      expect(body["leaderboard"].map { |row| row["user_id"] }).to contain_exactly(garcom.id)
    end

    it "agrega o ano inteiro quando period=year" do
      jan = create(:weekly_session, scheduled_at: Time.current.beginning_of_year + 10.days)
      later = create(:weekly_session, scheduled_at: Time.current.beginning_of_month + 1.day)

      create(:session_stat, weekly_session: jan, user: artilheiro, goals: 4, assists: 0)
      create(:session_stat, weekly_session: later, user: artilheiro, goals: 1, assists: 0)

      get "/api/v1/stats/leaderboard", params: { period: "year" }, headers: headers

      body = response.parsed_body
      expect(body["period"]).to eq("year")
      expect(body["leaderboard"].first).to include("user_id" => artilheiro.id, "goals" => 5)
    end

    it "usa periodo mensal como padrao quando invalido" do
      get "/api/v1/stats/leaderboard", params: { period: "decade" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["period"]).to eq("month")
    end

    it "exige autenticacao" do
      get "/api/v1/stats/leaderboard", params: { period: "month" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
