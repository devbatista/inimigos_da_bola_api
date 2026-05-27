require "rails_helper"

RSpec.describe WeeklySessions::CreateCurrent do
  around do |example|
    original = {
      "RACHA_WEEKDAY" => ENV["RACHA_WEEKDAY"],
      "RACHA_TIME" => ENV["RACHA_TIME"],
      "RACHA_MAX_PLAYERS" => ENV["RACHA_MAX_PLAYERS"]
    }
    ENV["RACHA_WEEKDAY"] = "monday"
    ENV["RACHA_TIME"] = "20:00"
    ENV["RACHA_MAX_PLAYERS"] = "18"

    travel_to Time.zone.parse("2026-05-27 10:00") do
      example.run
    end
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  it "creates the configured weekly session once" do
    first = described_class.new.call
    second = described_class.new.call

    expect(first).to be_success
    expect(second).to be_success
    expect(first.data).to eq(second.data)
    expect(WeeklySession.count).to eq(1)
    expect(first.data.max_players).to eq(18)
    expect(first.data.scheduled_at).to eq(Time.zone.parse("2026-05-25 20:00").utc)
  end
end
