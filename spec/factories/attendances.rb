FactoryBot.define do
  factory :attendance do
    weekly_session
    user
    kind { :registered }
    status { :confirmed }

    trait :declined do
      status { :declined }
    end

    trait :pending do
      status { :pending }
    end

    trait :waitlisted do
      status { :confirmed }
      sequence(:waitlist_position) { |n| n }
    end

    trait :guest do
      user { nil }
      kind { :guest }
      guest_name { "Guest Player" }
      association :created_by_admin, factory: [ :user, :admin ]
    end
  end
end
