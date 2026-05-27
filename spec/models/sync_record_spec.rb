require "rails_helper"

RSpec.describe SyncRecord do
  it "assigns UUID v7 ids to sync records" do
    user = create(:user)

    expect(user.id).to be_present
    expect(user.id.split("-").third).to start_with("7")
  end

  it "soft deletes records and exposes active/deleted scopes" do
    user = create(:user)

    expect(User.active).to include(user)

    user.soft_delete!

    expect(user.deleted_at).to be_present
    expect(User.active).not_to include(user)
    expect(User.deleted).to include(user)
  end
end
