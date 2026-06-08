require "rails_helper"

RSpec.describe WeeklySessions::CreateCurrentJob do
  around do |example|
    original = {
      "RACHA_WEEKDAY" => ENV["RACHA_WEEKDAY"],
      "RACHA_TIME" => ENV["RACHA_TIME"],
      "RACHA_MAX_PLAYERS" => ENV["RACHA_MAX_PLAYERS"]
    }
    ENV["RACHA_WEEKDAY"] = "monday"
    ENV["RACHA_TIME"] = "20:00"
    ENV["RACHA_MAX_PLAYERS"] = "20"

    travel_to Time.zone.parse("2026-05-27 08:00") do
      example.run
    end
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  it "enqueues on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "creates the current weekly session and broadcasts 'Racha aberto'" do
    push = instance_double(Notifications::Push, call: ServiceResult.success(nil))
    allow(Notifications::Push).to receive(:new).and_return(push)

    expect { described_class.new.perform }.to change(WeeklySession, :count).by(1)

    # Quarta 2026-05-27 -> proxima segunda (racha) e 2026-06-01.
    expect(Notifications::Push).to have_received(:new).with(
      hash_including(
        audience: :all,
        title: "Racha aberto",
        body: "O racha de segunda (01/06) está aberto. Você vai?"
      )
    )
    expect(push).to have_received(:call)
  end

  it "is idempotent within the same week and broadcasts only on creation" do
    push = instance_double(Notifications::Push, call: ServiceResult.success(nil))
    allow(Notifications::Push).to receive(:new).and_return(push)

    described_class.new.perform
    expect {
      described_class.new.perform
    }.not_to change(WeeklySession, :count)

    expect(Notifications::Push).to have_received(:new).once
    expect(push).to have_received(:call).once
  end

  it "does not broadcast when the service fails" do
    allow_any_instance_of(WeeklySessions::CreateCurrent)
      .to receive(:call).and_return(ServiceResult.failure("VALIDATION_ERROR", "boom"))
    allow(Notifications::Push).to receive(:new)

    described_class.new.perform

    expect(Notifications::Push).not_to have_received(:new)
  end
end
