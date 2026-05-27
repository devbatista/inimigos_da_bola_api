FactoryBot.define do
  factory :session_stat do
    weekly_session
    user
    goals { 1 }
    assists { 0 }
  end
end
