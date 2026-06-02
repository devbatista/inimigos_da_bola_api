require "rails_helper"

RSpec.describe SkillRatingPolicy do
  subject(:policy) { described_class.new(user, skill_rating) }

  let(:skill_rating) { build_stubbed(:skill_rating) }

  context "when user is nil" do
    let(:user) { nil }

    it { expect(policy.create?).to be(false) }
  end

  context "when user is a regular player" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.create?).to be(true) }
  end

  context "when user is an admin" do
    let(:user) { build_stubbed(:user, :admin) }

    it { expect(policy.create?).to be(true) }
  end
end
