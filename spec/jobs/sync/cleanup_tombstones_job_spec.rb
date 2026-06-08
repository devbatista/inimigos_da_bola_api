require "rails_helper"

RSpec.describe Sync::CleanupTombstonesJob do
  it "roda na fila default" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "remove fisicamente tombstones com mais de 90 dias" do
    travel_to Time.zone.parse("2026-06-08 12:00") do
      old_session = create(:weekly_session, deleted_at: 91.days.ago)
      old_user = create(:user, deleted_at: 91.days.ago)
      old_attendance = create(:attendance, weekly_session: old_session, user: old_user, deleted_at: 91.days.ago)
      old_stat = create(:session_stat, weekly_session: old_session, user: old_user, deleted_at: 91.days.ago)
      old_rating = create(:skill_rating, deleted_at: 91.days.ago)

      result = described_class.new.perform

      expect(result).to include(
        session_stats: 1,
        skill_ratings: 1,
        attendances: 1,
        weekly_sessions: 1,
        users: 1
      )
      expect(SessionStat.exists?(old_stat.id)).to be(false)
      expect(SkillRating.exists?(old_rating.id)).to be(false)
      expect(Attendance.exists?(old_attendance.id)).to be(false)
      expect(WeeklySession.exists?(old_session.id)).to be(false)
      expect(User.exists?(old_user.id)).to be(false)
    end
  end

  it "preserva tombstones dentro da janela de retencao" do
    travel_to Time.zone.parse("2026-06-08 12:00") do
      recent_user = create(:user, deleted_at: 90.days.ago)

      expect {
        described_class.new.perform
      }.not_to change(User, :count)
      expect(User.exists?(recent_user.id)).to be(true)
    end
  end

  it "preserva usuarios e sessoes com dependencias restantes" do
    travel_to Time.zone.parse("2026-06-08 12:00") do
      weekly_session = create(:weekly_session, deleted_at: 91.days.ago)
      user = create(:user, deleted_at: 91.days.ago)
      create(:attendance, weekly_session: weekly_session, user: user)

      result = described_class.new.perform

      expect(result).to include(weekly_sessions: 0, users: 0)
      expect(WeeklySession.exists?(weekly_session.id)).to be(true)
      expect(User.exists?(user.id)).to be(true)
    end
  end

  it "tem agendamento recorrente configurado" do
    schedule = YAML.safe_load(Rails.root.join("config/schedule.yml").read)

    expect(schedule.fetch("cleanup_sync_tombstones")).to include(
      "cron" => "30 3 * * *",
      "class" => "Sync::CleanupTombstonesJob",
      "queue" => "default"
    )
  end
end
