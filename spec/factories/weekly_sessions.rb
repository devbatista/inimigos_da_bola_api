FactoryBot.define do
  factory :weekly_session do
    scheduled_at { Time.zone.parse("2026-05-25 20:00") }
    max_players { 20 }
    status { :scheduled }
  end
end
