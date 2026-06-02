require "rails_helper"

RSpec.describe GuestAttendancePolicy do
  subject(:policy) { described_class.new(user, guest_attendance) }

  let(:guest_attendance) { build_stubbed(:attendance, :guest) }

  context "when user is nil" do
    let(:user) { nil }

    it { expect(policy.create?).to be_falsey }
    it { expect(policy.destroy?).to be_falsey }
  end

  context "when user is a regular player" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.create?).to be(false) }
    it { expect(policy.destroy?).to be(false) }
  end

  context "when user is an admin" do
    let(:user) { build_stubbed(:user, :admin) }

    it { expect(policy.create?).to be(true) }
    it { expect(policy.destroy?).to be(true) }
  end
end
