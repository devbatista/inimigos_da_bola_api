require "rails_helper"

RSpec.describe UserPolicy do
  subject(:policy) { described_class.new(user, record_user) }

  let(:record_user) { build_stubbed(:user) }

  context "when user is nil" do
    let(:user) { nil }

    it { expect(policy.show?).to be(false) }
    it { expect(policy.update?).to be(false) }
    it { expect(policy.invite?).to be_falsey }
  end

  context "when user is a regular player" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.show?).to be(true) }
    it { expect(policy.invite?).to be(false) }
  end

  context "when user is an admin" do
    let(:user) { build_stubbed(:user, :admin) }

    it { expect(policy.show?).to be(true) }
    it { expect(policy.invite?).to be(true) }
  end

  context "when user is the record" do
    let(:record_user) { build_stubbed(:user) }
    let(:user) { record_user }

    it { expect(policy.update?).to be(true) }
  end

  context "when user is not the record" do
    let(:user) { build_stubbed(:user) }

    it { expect(policy.update?).to be(false) }
  end
end
