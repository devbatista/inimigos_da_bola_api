require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it "has expected domain associations" do
      expect(described_class.reflect_on_association(:attendances).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:created_guest_attendances).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:given_skill_ratings).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:received_skill_ratings).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:session_stats).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:refresh_tokens).macro).to eq(:has_many)
    end
  end

  describe "validations" do
    it "requires name and email for active users" do
      user = build(:user, name: nil, email: nil)

      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
      expect(user.errors[:email]).to be_present
    end

    it "allows pending invitations without email" do
      user = build(:user, email: nil, encrypted_password: "", invitation_accepted_at: nil)

      expect(user).to be_valid
    end

    it "limits skill score to 0 through 100" do
      low = build(:user, skill_score: -0.01)
      high = build(:user, skill_score: 100.01)

      expect(low).not_to be_valid
      expect(low.errors[:skill_score]).to be_present
      expect(high).not_to be_valid
      expect(high.errors[:skill_score]).to be_present
    end

    it "allows duplicate email only after soft delete" do
      user = create(:user)
      duplicate = build(:user, email: user.email)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present

      user.soft_delete!

      expect(duplicate).to be_valid
    end

    it "assigns jti on create" do
      user = create(:user)

      expect(user.jti).to be_present
    end
  end
end
