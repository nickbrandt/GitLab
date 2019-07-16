class CreateCycleAnalyticsProjectStages < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  INDEX_NAME = 'index_cycle_analytics_stages_on_project_id_and_name'

  def change
    create_table :cycle_analytics_project_stages do |t|
      t.references :project, null: false, foreign_key: { to_table: :projects, on_delete: :cascade }
      t.string :name, null: false
      t.boolean :hidden, default: false, null: false
      t.boolean :custom, default: true, null: false
      t.integer :relative_position
      t.integer :start_event_identifier, null: false
      t.integer :end_event_identifier, null: false
      t.references :start_event_label, foreign_key: { to_table: :labels, on_delete: :cascade }
      t.references :end_event_label, foreign_key: { to_table: :labels, on_delete: :cascade }

      t.timestamps_with_timezone
    end

    add_index :cycle_analytics_project_stages, [:project_id, :name], unique: true, name: INDEX_NAME
    add_index :cycle_analytics_project_stages, [:relative_position]
  end
end
