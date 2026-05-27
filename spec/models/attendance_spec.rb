require "rails_helper"

RSpec.describe Attendance, type: :model do
  describe "associations" do
    it "belongs to weekly session, registered user, and guest creator" do
      expect(described_class.reflect_on_association(:weekly_session).macro).to eq(:belongs_to)
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
      expect(described_class.reflect_on_association(:created_by_admin).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires user and forbids guest data for registered attendances" do
      attendance = build(:attendance, user: nil)

      expect(attendance).not_to be_valid
      expect(attendance.errors[:user_id]).to be_present

      attendance = build(:attendance, guest_name: "Guest", created_by_admin: create(:user, :admin))

      expect(attendance).not_to be_valid
      expect(attendance.errors[:guest_name]).to be_present
      expect(attendance.errors[:created_by_admin_id]).to be_present
    end

    it "requires guest name and admin creator for guest attendances" do
      attendance = build(:attendance, :guest, guest_name: nil, created_by_admin: nil)

      expect(attendance).not_to be_valid
      expect(attendance.errors[:guest_name]).to be_present
      expect(attendance.errors[:created_by_admin_id]).to be_present
    end

    it "forbids a user on guest attendances" do
      attendance = build(:attendance, :guest, user: create(:user))

      expect(attendance).not_to be_valid
      expect(attendance.errors[:user_id]).to be_present
    end

    it "requires positive waitlist positions" do
      attendance = build(:attendance, waitlist_position: 0)

      expect(attendance).not_to be_valid
      expect(attendance.errors[:waitlist_position]).to be_present
    end

    it "allows one active registered attendance per user and weekly session" do
      attendance = create(:attendance)
      duplicate = build(:attendance, user: attendance.user, weekly_session: attendance.weekly_session)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present

      attendance.soft_delete!

      expect(duplicate).to be_valid
    end
  end
end
