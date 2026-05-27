require "rails_helper"

RSpec.describe SkillRating, type: :model do
  describe "associations" do
    it "belongs to evaluator and evaluated users" do
      expect(described_class.reflect_on_association(:evaluator_user).macro).to eq(:belongs_to)
      expect(described_class.reflect_on_association(:evaluated_user).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires score between 0 and 100" do
      low = build(:skill_rating, score: -1)
      high = build(:skill_rating, score: 101)

      expect(low).not_to be_valid
      expect(low.errors[:score]).to be_present
      expect(high).not_to be_valid
      expect(high.errors[:score]).to be_present
    end

    it "forbids self rating" do
      user = create(:user)
      rating = build(:skill_rating, evaluator_user: user, evaluated_user: user)

      expect(rating).not_to be_valid
      expect(rating.errors[:evaluated_user_id]).to be_present
    end

    it "allows one active rating per evaluator and evaluated user" do
      rating = create(:skill_rating)
      duplicate = build(
        :skill_rating,
        evaluator_user: rating.evaluator_user,
        evaluated_user: rating.evaluated_user
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:evaluator_user_id]).to be_present

      rating.soft_delete!

      expect(duplicate).to be_valid
    end
  end
end
