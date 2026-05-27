class CreateWeeklySessions < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_sessions, id: :uuid do |t|
      t.datetime :scheduled_at, null: false
      t.integer :max_players, null: false, default: 20
      t.string :status, null: false, default: "scheduled"
      t.datetime :deleted_at
      t.integer :version, null: false, default: 0
      t.timestamps
    end

    add_index :weekly_sessions, :scheduled_at
    add_check_constraint :weekly_sessions, "status IN ('scheduled', 'closed', 'canceled')", name: "weekly_sessions_status_check"
    add_check_constraint :weekly_sessions, "max_players > 0", name: "weekly_sessions_max_players_check"
  end
end
