require "rails_helper"

RSpec.describe SessionStatPolicy do
  subject(:policy) { described_class.new(user, session_stat) }

  let(:session_stat) { build_stubbed(:session_stat) }

  context "when user is nil" do
    let(:user) { nil }

    it { expect(policy.create?).to be_falsey }
    it { expect(policy.update?).to be_falsey }
    it { expect(policy.leaderboard?).to be(false) }
  end

  context "when user is a regular player" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.create?).to be(false) }
    it { expect(policy.update?).to be(false) }
    it { expect(policy.leaderboard?).to be(true) }
  end

  context "when user is an admin" do
    let(:user) { build_stubbed(:user, :admin) }

    it { expect(policy.create?).to be(true) }
    it { expect(policy.update?).to be(true) }
    it { expect(policy.leaderboard?).to be(true) }
  end
end
