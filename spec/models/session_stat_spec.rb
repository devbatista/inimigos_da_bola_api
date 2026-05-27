require "rails_helper"

RSpec.describe SessionStat, type: :model do
  describe "associations" do
    it "belongs to weekly session and user" do
      expect(described_class.reflect_on_association(:weekly_session).macro).to eq(:belongs_to)
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires non-negative goals and assists" do
      stat = build(:session_stat, goals: -1, assists: -1)

      expect(stat).not_to be_valid
      expect(stat.errors[:goals]).to be_present
      expect(stat.errors[:assists]).to be_present
    end

    it "allows one active stat per user and weekly session" do
      stat = create(:session_stat)
      duplicate = build(:session_stat, user: stat.user, weekly_session: stat.weekly_session)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present

      stat.soft_delete!

      expect(duplicate).to be_valid
    end
  end
end
