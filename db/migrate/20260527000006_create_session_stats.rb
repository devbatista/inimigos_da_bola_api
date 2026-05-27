class CreateSessionStats < ActiveRecord::Migration[8.1]
  def change
    create_table :session_stats, id: :uuid do |t|
      t.references :weekly_session, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.integer :goals, null: false, default: 0
      t.integer :assists, null: false, default: 0
      t.datetime :deleted_at
      t.integer :version, null: false, default: 0
      t.timestamps
    end

    add_index :session_stats, [ :weekly_session_id, :user_id ],
      unique: true,
      where: "deleted_at IS NULL"
    add_check_constraint :session_stats, "goals >= 0", name: "session_stats_goals_check"
    add_check_constraint :session_stats, "assists >= 0", name: "session_stats_assists_check"
  end
end
