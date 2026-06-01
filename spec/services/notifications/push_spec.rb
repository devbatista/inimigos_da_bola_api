require "rails_helper"

RSpec.describe Notifications::Push do
  describe "#call" do
    it "resolve a audiencia 'all' para usuarios ativos com token" do
      create(:user, fcm_token: "t1")
      create(:user, fcm_token: "t2")
      create(:user, fcm_token: nil)

      result = described_class.new(audience: :all, title: "Oi", body: "Tudo bem?").call

      expect(result).to be_success
      expect(result.data[:tokens_count]).to eq(2)
      expect(result.data[:silent]).to be(false)
      expect(result.data[:payload][:notification]).to eq(title: "Oi", body: "Tudo bem?")
    end

    it "resolve a audiencia 'admins' apenas para admins com token" do
      create(:user, :admin, fcm_token: "admin-token")
      create(:user, fcm_token: "player-token")

      result = described_class.new(audience: :admins, title: "Admin", body: "Aviso").call

      expect(result.data[:tokens_count]).to eq(1)
    end

    it "resolve a audiencia 'user' para um unico usuario" do
      target = create(:user, fcm_token: "target")
      create(:user, fcm_token: "outro")

      result = described_class.new(audience: :user, user: target, title: "Oi", body: "Voce").call

      expect(result.data[:tokens_count]).to eq(1)
    end

    it "monta data message silenciosa quando nao ha title/body" do
      create(:user, fcm_token: "t1")

      result = described_class.new(audience: :all, data: { type: "sync" }).call

      expect(result.data[:silent]).to be(true)
      expect(result.data[:payload]).to eq(data: { "type" => "sync" })
      expect(result.data[:payload]).not_to have_key(:notification)
    end

    it "falha com audiencia invalida" do
      result = described_class.new(audience: :everyone, title: "x", body: "y").call

      expect(result).to be_failure
      expect(result.code).to eq("VALIDATION_ERROR")
    end

    it "falha quando audiencia 'user' nao recebe usuario" do
      result = described_class.new(audience: :user, title: "x", body: "y").call

      expect(result).to be_failure
      expect(result.code).to eq("VALIDATION_ERROR")
    end
  end
end
