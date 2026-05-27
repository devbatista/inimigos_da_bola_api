# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_27_000009) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "attendances", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by_admin_id"
    t.datetime "deleted_at"
    t.string "guest_name"
    t.string "kind", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.integer "version", default: 0, null: false
    t.integer "waitlist_position"
    t.uuid "weekly_session_id", null: false
    t.index ["created_by_admin_id"], name: "index_attendances_on_created_by_admin_id"
    t.index ["user_id", "weekly_session_id"], name: "idx_attendances_registered_unique", unique: true, where: "((deleted_at IS NULL) AND ((kind)::text = 'registered'::text))"
    t.index ["user_id"], name: "index_attendances_on_user_id"
    t.index ["weekly_session_id", "guest_name"], name: "index_attendances_on_weekly_session_id_and_guest_name"
    t.index ["weekly_session_id"], name: "index_attendances_on_weekly_session_id"
    t.check_constraint "kind::text = 'registered'::text AND created_by_admin_id IS NULL OR kind::text = 'guest'::text AND created_by_admin_id IS NOT NULL", name: "attendances_created_by_admin_check"
    t.check_constraint "kind::text = 'registered'::text AND user_id IS NOT NULL AND guest_name IS NULL OR kind::text = 'guest'::text AND user_id IS NULL AND guest_name IS NOT NULL", name: "attendances_kind_data_check"
    t.check_constraint "kind::text = ANY (ARRAY['registered'::character varying, 'guest'::character varying]::text[])", name: "attendances_kind_check"
    t.check_constraint "status::text = ANY (ARRAY['confirmed'::character varying, 'declined'::character varying, 'pending'::character varying]::text[])", name: "attendances_status_check"
    t.check_constraint "waitlist_position IS NULL OR waitlist_position > 0", name: "attendances_waitlist_position_check"
  end

  create_table "processed_mutations", primary_key: "mutation_id", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "applied_at", null: false
  end

  create_table "refresh_tokens", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id", "revoked_at"], name: "index_refresh_tokens_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "session_stats", id: :uuid, default: nil, force: :cascade do |t|
    t.integer "assists", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "goals", default: 0, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.integer "version", default: 0, null: false
    t.uuid "weekly_session_id", null: false
    t.index ["user_id"], name: "index_session_stats_on_user_id"
    t.index ["weekly_session_id", "user_id"], name: "index_session_stats_on_weekly_session_id_and_user_id", unique: true, where: "(deleted_at IS NULL)"
    t.index ["weekly_session_id"], name: "index_session_stats_on_weekly_session_id"
    t.check_constraint "assists >= 0", name: "session_stats_assists_check"
    t.check_constraint "goals >= 0", name: "session_stats_goals_check"
  end

  create_table "skill_ratings", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.uuid "evaluated_user_id", null: false
    t.uuid "evaluator_user_id", null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 0, null: false
    t.index ["evaluated_user_id"], name: "index_skill_ratings_on_evaluated_user_id"
    t.index ["evaluator_user_id", "evaluated_user_id"], name: "idx_skill_ratings_pair_unique", unique: true, where: "(deleted_at IS NULL)"
    t.check_constraint "evaluator_user_id <> evaluated_user_id", name: "skill_ratings_no_self_check"
    t.check_constraint "score >= 0 AND score <= 100", name: "skill_ratings_score_check"
  end

  create_table "users", id: :uuid, default: nil, force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.citext "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "fcm_token"
    t.boolean "goalkeeper", default: false, null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.string "jti", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "player_type", default: "casual", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.decimal "skill_score", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.integer "version", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(deleted_at IS NULL)"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.check_constraint "player_type::text = ANY (ARRAY['monthly'::character varying, 'casual'::character varying]::text[])", name: "users_player_type_check"
    t.check_constraint "skill_score IS NULL OR skill_score >= 0::numeric AND skill_score <= 100::numeric", name: "users_skill_score_check"
  end

  create_table "weekly_sessions", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "max_players", default: 20, null: false
    t.datetime "scheduled_at", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 0, null: false
    t.index ["scheduled_at"], name: "idx_weekly_sessions_scheduled_at_active_unique", unique: true, where: "(deleted_at IS NULL)"
    t.index ["scheduled_at"], name: "index_weekly_sessions_on_scheduled_at"
    t.check_constraint "max_players > 0", name: "weekly_sessions_max_players_check"
    t.check_constraint "status::text = ANY (ARRAY['scheduled'::character varying, 'closed'::character varying, 'canceled'::character varying]::text[])", name: "weekly_sessions_status_check"
  end

  add_foreign_key "attendances", "users"
  add_foreign_key "attendances", "users", column: "created_by_admin_id"
  add_foreign_key "attendances", "weekly_sessions"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "session_stats", "users"
  add_foreign_key "session_stats", "weekly_sessions"
  add_foreign_key "skill_ratings", "users", column: "evaluated_user_id"
  add_foreign_key "skill_ratings", "users", column: "evaluator_user_id"
end
