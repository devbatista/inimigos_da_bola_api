require "rails_helper"

RSpec.describe Notifications::PushJob do
  it "roda na fila default" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "chama Notifications::Push com os argumentos mapeados" do
    push = instance_double(Notifications::Push, call: ServiceResult.success(nil))
    allow(Notifications::Push).to receive(:new).and_return(push)

    described_class.new.perform(
      audience: "all",
      title: "Oi",
      body: "Corpo",
      data: { "type" => "sync" }
    )

    expect(Notifications::Push).to have_received(:new).with(
      audience: "all",
      title: "Oi",
      body: "Corpo",
      data: { "type" => "sync" },
      user: nil
    )
    expect(push).to have_received(:call)
  end

  it "carrega o usuario quando recebe user_id" do
    user = create(:user)
    push = instance_double(Notifications::Push, call: ServiceResult.success(nil))
    allow(Notifications::Push).to receive(:new).and_return(push)

    described_class.new.perform(audience: "user", user_id: user.id, title: "Oi", body: "Voce")

    expect(Notifications::Push).to have_received(:new).with(hash_including(user: user))
  end
end
