require "rails_helper"

RSpec.describe WeeklySession, type: :model do
  describe "associations" do
    it "has attendances and session stats" do
      expect(described_class.reflect_on_association(:attendances).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:session_stats).macro).to eq(:has_many)
    end
  end

  describe "validations" do
    it "requires scheduled_at" do
      weekly_session = build(:weekly_session, scheduled_at: nil)

      expect(weekly_session).not_to be_valid
      expect(weekly_session.errors[:scheduled_at]).to be_present
    end

    it "requires positive max players" do
      weekly_session = build(:weekly_session, max_players: 0)

      expect(weekly_session).not_to be_valid
      expect(weekly_session.errors[:max_players]).to be_present
    end

    it "allows one active session per scheduled time" do
      weekly_session = create(:weekly_session)
      duplicate = build(:weekly_session, scheduled_at: weekly_session.scheduled_at)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:scheduled_at]).to be_present

      weekly_session.soft_delete!

      expect(duplicate).to be_valid
    end
  end
end
