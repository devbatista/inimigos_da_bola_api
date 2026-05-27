FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "player#{n}@example.com" }
    name { "Player" }
    password { "password123" }
    password_confirmation { "password123" }
    player_type { :casual }

    trait :admin do
      admin { true }
    end
  end
end
