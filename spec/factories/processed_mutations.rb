FactoryBot.define do
  factory :processed_mutation do
    mutation_id { SecureRandom.uuid }
    applied_at { Time.current }
  end
end
