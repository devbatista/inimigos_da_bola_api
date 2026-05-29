require "rails_helper"

RSpec.describe WeeklySessionPolicy do
  subject(:policy) { described_class.new(user, weekly_session) }

  let(:weekly_session) { build_stubbed(:weekly_session) }

  context "when user is nil" do
    let(:user) { nil }

    it { expect(policy.show?).to be(false) }
    it { expect(policy.current?).to be(false) }
  end

  context "when user is a regular player" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.show?).to be(true) }
    it { expect(policy.current?).to be(true) }
  end

  context "when user is an admin" do
    let(:user) { build_stubbed(:user, :admin) }

    it { expect(policy.show?).to be(true) }
    it { expect(policy.current?).to be(true) }
  end
end
