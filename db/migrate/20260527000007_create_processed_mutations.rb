class CreateProcessedMutations < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_mutations, id: false do |t|
      t.uuid :mutation_id, null: false, primary_key: true
      t.datetime :applied_at, null: false
    end
  end
end
