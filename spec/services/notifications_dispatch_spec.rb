require "rails_helper"

# Garante que cada mutacao de presenca dispara as notificacoes esperadas
# (push direcionado + data message silenciosa de sync) via Notifications::PushJob.
RSpec.describe "Disparo de notificacoes de presenca" do
  let(:weekly_session) { create(:weekly_session, max_players: 20) }
  let(:player) { create(:user, name: "João") }
  let(:admin) { create(:user, :admin) }

  before { allow(Notifications::PushJob).to receive(:perform_later) }

  describe Attendances::Confirm do
    it "notifica admins sobre nova confirmacao e dispara sync" do
      described_class.new(weekly_session: weekly_session, user: player).call

      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "admins",
        title: "Nova confirmação",
        body: "João confirmou presença no racha.",
        data: hash_including(type: "attendance_confirmed")
      )
      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "all",
        data: hash_including(type: "sync")
      )
    end
  end

  describe Attendances::Decline do
    it "notifica admins sobre cancelamento e dispara sync" do
      create(:attendance, weekly_session: weekly_session, user: player, status: :confirmed)

      described_class.new(weekly_session: weekly_session, user: player).call

      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "admins",
        title: "Cancelamento de presença",
        body: "João cancelou presença no racha.",
        data: hash_including(type: "attendance_declined")
      )
    end
  end

  describe Attendances::PromoteWaitlist do
    it "notifica o jogador promovido e dispara sync" do
      create(:attendance, weekly_session: weekly_session, user: player, status: :confirmed, waitlist_position: 1)

      described_class.new(weekly_session: weekly_session).call

      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "user",
        user_id: player.id,
        title: "Abriu vaga!",
        body: "Você está confirmado para hoje.",
        data: hash_including(type: "waitlist_promoted")
      )
      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "all",
        data: hash_including(type: "sync")
      )
    end

    it "nao envia push direcionado quando o promovido e avulso" do
      create(:attendance, :guest, weekly_session: weekly_session, status: :confirmed, waitlist_position: 1)

      described_class.new(weekly_session: weekly_session).call

      expect(Notifications::PushJob).not_to have_received(:perform_later).with(hash_including(audience: "user"))
      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "all",
        data: hash_including(type: "sync")
      )
    end
  end

  describe GuestAttendances::Create do
    it "notifica admins sobre avulso adicionado e dispara sync" do
      described_class.new(weekly_session: weekly_session, admin: admin, guest_name: "Visitante").call

      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "admins",
        title: "Avulso adicionado",
        body: "Visitante foi adicionado ao racha.",
        data: hash_including(type: "guest_added")
      )
    end
  end

  describe GuestAttendances::Destroy do
    it "notifica admins sobre avulso removido e dispara sync" do
      guest = create(:attendance, :guest, weekly_session: weekly_session, guest_name: "Visitante", status: :confirmed)

      described_class.new(attendance: guest).call

      expect(Notifications::PushJob).to have_received(:perform_later).with(
        audience: "admins",
        title: "Avulso removido",
        body: "Visitante foi removido do racha.",
        data: hash_including(type: "guest_removed")
      )
    end
  end
end
