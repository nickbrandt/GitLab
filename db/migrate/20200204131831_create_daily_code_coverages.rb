# frozen_string_literal: true

class CreateDailyCodeCoverages < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :daily_code_coverages do |t|
      t.date :date, null: false
      t.integer :project_id, null: false
      t.integer :last_pipeline_id, null: false
      t.float :coverage, null: false
      t.string :ref, null: false # rubocop:disable Migration/AddLimitToStringColumns
      t.string :name, null: false # rubocop:disable Migration/AddLimitToStringColumns

      t.index [:project_id, :ref, :name, :date], name: 'index_daily_code_coverage_unique_columns', unique: true, order: { date: :desc }
      t.foreign_key :projects, on_delete: :cascade
      t.foreign_key :ci_pipelines, column: :last_pipeline_id, on_delete: :cascade
    end
  end
end
