# frozen_string_literal: true

class CreateAnalyticsRepositoryFileEditsTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :analytics_repository_file_edits do |t|
      t.references :project,
        index: true,
        foreign_key: { on_delete: :cascade }, null: false
      t.references :analytics_repository_file,
        index: false,
        foreign_key: { on_delete: :cascade },
        null: false
      t.references :analytics_repository_commit,
        index: { name: 'index_analytics_repository_file_edits_on_commit_id' },
        foreign_key: { on_delete: :cascade },
        null: false
      t.integer :num_edits,
        null: false,
        default: 0
    end

    add_index :analytics_repository_file_edits,
      [:analytics_repository_file_id, :analytics_repository_commit_id, :project_id],
      name: 'index_analytics_file_edits_on_commit_id_file_id_and_project_id',
      unique: true
  end
end
