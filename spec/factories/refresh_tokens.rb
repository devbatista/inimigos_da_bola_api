FactoryBot.define do
  factory :refresh_token do
    user
    sequence(:token_digest) { |n| "refresh-token-digest-#{n}-#{SecureRandom.hex(16)}" }
    expires_at { 30.days.from_now }

    trait :revoked do
      revoked_at { Time.current }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
