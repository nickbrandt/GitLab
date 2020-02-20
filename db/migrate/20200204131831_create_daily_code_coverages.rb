# frozen_string_literal: true

class CreateDailyCodeCoverages < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :ci_daily_code_coverages do |t|
      t.date :date, null: false
      t.bigint :project_id, null: false
      t.bigint :last_build_id, null: false
      t.float :coverage, null: false
      t.string :ref, null: false # rubocop:disable Migration/AddLimitToStringColumns
      t.string :name, null: false # rubocop:disable Migration/AddLimitToStringColumns

      t.index :last_build_id
      t.index [:project_id, :ref, :name, :date], name: 'index_daily_code_coverage_unique_columns', unique: true, order: { date: :desc }
      t.foreign_key :projects, on_delete: :cascade
      t.foreign_key :ci_builds, column: :last_build_id, on_delete: :cascade
    end
  end
end
