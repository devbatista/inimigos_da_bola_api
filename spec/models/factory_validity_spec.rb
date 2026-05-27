require "rails_helper"

RSpec.describe "factories" do
  it "creates valid records for every model factory" do
    expect(create(:user)).to be_persisted
    expect(create(:user, :admin)).to be_admin
    expect(create(:weekly_session)).to be_persisted
    expect(create(:attendance)).to be_persisted
    expect(create(:attendance, :guest)).to be_persisted
    expect(create(:skill_rating)).to be_persisted
    expect(create(:session_stat)).to be_persisted
    expect(create(:processed_mutation)).to be_persisted
    expect(create(:refresh_token)).to be_persisted
  end
end
