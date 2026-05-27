class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.citext :email, null: false
      t.string :name, null: false
      t.string :phone
      t.boolean :admin, null: false, default: false
      t.string :player_type, null: false, default: "casual"
      t.decimal :skill_score, precision: 5, scale: 2
      t.boolean :goalkeeper, null: false, default: false
      t.string :fcm_token

      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :jti, null: false

      t.string :invitation_token
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at

      t.datetime :deleted_at
      t.integer :version, null: false, default: 0
      t.timestamps
    end

    add_index :users, :email, unique: true, where: "deleted_at IS NULL"
    add_index :users, :jti, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :invitation_token, unique: true
    add_check_constraint :users, "player_type IN ('monthly', 'casual')", name: "users_player_type_check"
    add_check_constraint :users, "skill_score IS NULL OR (skill_score >= 0 AND skill_score <= 100)", name: "users_skill_score_check"
  end
end
