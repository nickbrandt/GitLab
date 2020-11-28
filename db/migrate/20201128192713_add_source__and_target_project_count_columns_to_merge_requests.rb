# frozen_string_literal: true

class AddSourceAndTargetProjectCountColumnsToMergeRequests < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :merge_requests, :total_pipelines_count, :integer
    add_column :merge_requests, :source_project_pipelines_count, :integer
    add_column :merge_requests, :target_project_pipelines_count, :integer
  end
end
