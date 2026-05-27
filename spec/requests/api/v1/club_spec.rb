require "rails_helper"

RSpec.describe "Club", type: :request do
  describe "GET /api/v1/club" do
    around do |example|
      climate = {
        "RACHA_WEEKDAY" => "monday",
        "RACHA_TIME" => "20:00",
        "RACHA_LOCATION" => "Arena X",
        "RACHA_MAX_PLAYERS" => "20"
      }
      original = climate.keys.index_with { |key| ENV[key] }
      climate.each { |key, value| ENV[key] = value }
      example.run
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end

    it "returns fixed club settings" do
      get "/api/v1/club"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "weekday" => "monday",
        "time" => "20:00",
        "location" => "Arena X",
        "max_players" => 20
      )
    end
  end
end
