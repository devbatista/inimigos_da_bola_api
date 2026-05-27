class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.references :weekly_session, null: false, type: :uuid, foreign_key: true
      t.string :kind, null: false
      t.string :guest_name
      t.references :created_by_admin, type: :uuid, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.integer :waitlist_position
      t.datetime :deleted_at
      t.integer :version, null: false, default: 0
      t.timestamps
    end

    add_index :attendances, [ :user_id, :weekly_session_id ],
      unique: true,
      where: "deleted_at IS NULL AND kind = 'registered'",
      name: "idx_attendances_registered_unique"
    add_index :attendances, [ :weekly_session_id, :guest_name ]
    add_check_constraint :attendances, "kind IN ('registered', 'guest')", name: "attendances_kind_check"
    add_check_constraint :attendances, "status IN ('confirmed', 'declined', 'pending')", name: "attendances_status_check"
    add_check_constraint :attendances,
      "(kind = 'registered' AND user_id IS NOT NULL AND guest_name IS NULL) OR (kind = 'guest' AND user_id IS NULL AND guest_name IS NOT NULL)",
      name: "attendances_kind_data_check"
  end
end
