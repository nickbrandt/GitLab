# frozen_string_literal: true

class CreateAnalyticsRepositoryCommitsTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :analytics_repository_commits do |t|
      t.references :project,
        index: false,
        foreign_key: { on_delete: :cascade },
        null: false
      t.binary :commit_sha,
        null: false
      t.datetime_with_timezone :committed_at,
        null: false
    end

    add_index :analytics_repository_commits, [:project_id, :commit_sha], unique: true
  end
end
