require "rails_helper"

RSpec.describe Notifications::RachaReminderJob do
  it "roda na fila default" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "notifica todos quando ha racha dentro da janela de ~1h" do
    weekly_session = create(:weekly_session, scheduled_at: 50.minutes.from_now)
    push = instance_double(Notifications::Push, call: ServiceResult.success(nil))
    allow(Notifications::Push).to receive(:new).and_return(push)

    described_class.new.perform

    expect(Notifications::Push).to have_received(:new).with(
      hash_including(
        audience: :all,
        title: "Racha hoje",
        body: "Em 1h tem racha. Já confirmou?",
        data: { weekly_session_id: weekly_session.id, type: "weekly_session_reminder" }
      )
    )
    expect(push).to have_received(:call)
  end

  it "nao notifica quando nao ha racha proximo" do
    create(:weekly_session, scheduled_at: 5.hours.from_now)
    allow(Notifications::Push).to receive(:new)

    described_class.new.perform

    expect(Notifications::Push).not_to have_received(:new)
  end
end
