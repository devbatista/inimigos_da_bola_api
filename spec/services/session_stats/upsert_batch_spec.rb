require "rails_helper"

RSpec.describe SessionStats::UpsertBatch do
  let(:weekly_session) { create(:weekly_session, scheduled_at: 1.hour.ago) }
  let(:player) { create(:user) }

  before { create(:attendance, weekly_session: weekly_session, user: player, status: :confirmed) }

  def stats_for(user, goals:, assists:)
    [ { user_id: user.id, goals: goals, assists: assists } ]
  end

  it "cria stats para jogador presente no racha" do
    result = described_class.new(
      weekly_session: weekly_session,
      stats: stats_for(player, goals: 3, assists: 1)
    ).call

    expect(result).to be_success
    stat = weekly_session.session_stats.active.find_by(user_id: player.id)
    expect(stat.goals).to eq(3)
    expect(stat.assists).to eq(1)
  end

  it "atualiza stats existentes do mesmo jogador" do
    create(:session_stat, weekly_session: weekly_session, user: player, goals: 1, assists: 0)

    result = described_class.new(
      weekly_session: weekly_session,
      stats: stats_for(player, goals: 5, assists: 2)
    ).call

    expect(result).to be_success
    expect(weekly_session.session_stats.active.where(user_id: player.id).count).to eq(1)
    expect(weekly_session.session_stats.active.find_by(user_id: player.id).goals).to eq(5)
  end

  it "rejeita lista vazia" do
    result = described_class.new(weekly_session: weekly_session, stats: []).call

    expect(result).to be_failure
    expect(result.code).to eq("VALIDATION_ERROR")
  end

  it "bloqueia jogador sem presenca registrada no racha" do
    outsider = create(:user)

    result = described_class.new(
      weekly_session: weekly_session,
      stats: stats_for(outsider, goals: 1, assists: 1)
    ).call

    expect(result).to be_failure
    expect(result.code).to eq("STATS_USER_NOT_IN_SESSION")
  end

  it "bloqueia edicao depois de 24h do racha" do
    weekly_session.update_column(:scheduled_at, 25.hours.ago)

    result = described_class.new(
      weekly_session: weekly_session,
      stats: stats_for(player, goals: 1, assists: 1)
    ).call

    expect(result).to be_failure
    expect(result.code).to eq("STATS_LOCKED")
  end

  it "permite edicao dentro da janela de 24h" do
    weekly_session.update_column(:scheduled_at, 23.hours.ago)

    result = described_class.new(
      weekly_session: weekly_session,
      stats: stats_for(player, goals: 2, assists: 2)
    ).call

    expect(result).to be_success
  end

  it "faz rollback quando uma entrada e invalida" do
    result = described_class.new(
      weekly_session: weekly_session,
      stats: stats_for(player, goals: -1, assists: 0)
    ).call

    expect(result).to be_failure
    expect(result.code).to eq("VALIDATION_ERROR")
    expect(weekly_session.session_stats.active.count).to eq(0)
  end
end
