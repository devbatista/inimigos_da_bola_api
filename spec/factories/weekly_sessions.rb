FactoryBot.define do
  factory :weekly_session do
    sequence(:scheduled_at) { |n| Time.current.change(usec: 0) + n.days + SecureRandom.random_number(86_400).seconds }
    max_players { 20 }
    status { :scheduled }
  end
end
