require "rails_helper"

RSpec.describe AttendancePolicy do
  subject(:policy) { described_class.new(user, attendance) }

  let(:attendance) { build_stubbed(:attendance) }

  context "when user is nil" do
    let(:user) { nil }

    it { expect(policy.index?).to be(false) }
    it { expect(policy.create?).to be(false) }
    it { expect(policy.update?).to be(false) }
  end

  context "when user is a regular player" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.index?).to be(true) }
    it { expect(policy.create?).to be(true) }
  end

  context "when user owns the attendance" do
    let(:user) { build_stubbed(:user) }
    let(:attendance) { build_stubbed(:attendance, user: user) }

    it { expect(policy.update?).to be(true) }
  end

  context "when user does not own the attendance" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.update?).to be(false) }
  end
end
