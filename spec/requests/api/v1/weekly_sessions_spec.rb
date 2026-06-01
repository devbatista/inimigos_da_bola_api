require "rails_helper"

RSpec.describe "Weekly sessions", type: :request do
  describe "GET /api/v1/weekly_sessions/current" do
    around do |example|
      original = {
        "RACHA_WEEKDAY" => ENV["RACHA_WEEKDAY"],
        "RACHA_TIME" => ENV["RACHA_TIME"],
        "RACHA_MAX_PLAYERS" => ENV["RACHA_MAX_PLAYERS"]
      }
      ENV["RACHA_WEEKDAY"] = "monday"
      ENV["RACHA_TIME"] = "20:00"
      ENV["RACHA_MAX_PLAYERS"] = "20"

      travel_to Time.zone.parse("2026-05-27 10:00") do
        example.run
      end
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end

    it "requires authentication" do
      get "/api/v1/weekly_sessions/current"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current weekly session for authenticated users" do
      sign_in create(:user)

      get "/api/v1/weekly_sessions/current"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "max_players" => 20,
        "confirmed_attendances_count" => 0,
        "status" => "scheduled"
      )
    end
  end

  describe "GET /api/v1/weekly_sessions/:id" do
    it "returns the public confirmed attendances count" do
      user = create(:user)
      weekly_session = create(:weekly_session)
      create(:attendance, weekly_session: weekly_session, status: :confirmed)
      create(:attendance, :guest, weekly_session: weekly_session, status: :confirmed)
      create(:attendance, weekly_session: weekly_session, status: :confirmed, waitlist_position: 1)
      create(:attendance, :declined, weekly_session: weekly_session)
      sign_in user

      get "/api/v1/weekly_sessions/#{weekly_session.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "id" => weekly_session.id,
        "confirmed_attendances_count" => 2
      )
    end
  end
end
