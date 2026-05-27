class CreateSkillRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_ratings, id: :uuid do |t|
      t.references :evaluator_user, null: false, type: :uuid, foreign_key: { to_table: :users }, index: false
      t.references :evaluated_user, null: false, type: :uuid, foreign_key: { to_table: :users }, index: false
      t.integer :score, null: false
      t.datetime :deleted_at
      t.integer :version, null: false, default: 0
      t.timestamps
    end

    add_index :skill_ratings, [ :evaluator_user_id, :evaluated_user_id ],
      unique: true,
      where: "deleted_at IS NULL",
      name: "idx_skill_ratings_pair_unique"
    add_index :skill_ratings, :evaluated_user_id
    add_check_constraint :skill_ratings, "score >= 0 AND score <= 100", name: "skill_ratings_score_check"
    add_check_constraint :skill_ratings, "evaluator_user_id <> evaluated_user_id", name: "skill_ratings_no_self_check"
  end
end
