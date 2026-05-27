FactoryBot.define do
  factory :skill_rating do
    association :evaluator_user, factory: :user
    association :evaluated_user, factory: :user
    score { 75 }
  end
end
