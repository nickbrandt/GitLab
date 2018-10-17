class AddVulnOccurrencePipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :vulnerability_occurrence_pipelines, id: :bigserial do |t|
      t.timestamps_with_timezone null: false

      t.bigint :occurrence_id, null: false
      t.foreign_key :vulnerability_occurrences, column: :occurrence_id, on_delete: :cascade
      t.integer :pipeline_id, null: false
      t.foreign_key :ci_pipelines, column: :pipeline_id, on_delete: :cascade

      t.index :pipeline_id
      t.index [:occurrence_id, :pipeline_id],
        unique: true,
        name: 'vulnerability_occurrence_pipelines_on_unique_keys'
    end
  end
end
