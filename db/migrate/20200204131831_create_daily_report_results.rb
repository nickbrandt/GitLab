# frozen_string_literal: true

class CreateDailyReportResults < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :ci_daily_report_results do |t|
      t.date :date, null: false
      t.bigint :project_id, null: false
      t.bigint :last_pipeline_id, null: false
      t.float :value, null: false
      t.integer :param, limit: 2, null: false
      t.string :ref_path, null: false # rubocop:disable Migration/AddLimitToStringColumns
      t.string :title, null: false # rubocop:disable Migration/AddLimitToStringColumns

      t.index :last_pipeline_id
      t.index [:project_id, :ref_path, :param, :title, :date], name: 'index_daily_build_report_metrics_unique_columns', unique: true, order: { date: :desc }
      t.foreign_key :projects, on_delete: :cascade
      t.foreign_key :ci_pipelines, column: :last_pipeline_id, on_delete: :cascade
    end
  end
end
