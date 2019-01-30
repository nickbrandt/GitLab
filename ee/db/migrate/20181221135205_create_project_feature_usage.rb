# frozen_string_literal: true

class CreateProjectFeatureUsage < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_feature_usages, id: false, primary_key: :project_id do |t|
      t.references :project,
                   foreign_key: { on_delete: :cascade },
                   null: false,
                   primary_key: true

      t.timestamp :jira_dvcs_cloud_last_sync_at
      t.timestamp :jira_dvcs_server_last_sync_at

      t.index [:jira_dvcs_cloud_last_sync_at, :project_id], name: "idx_proj_feat_usg_on_jira_dvcs_cloud_last_sync_at_and_proj_id", where: "(jira_dvcs_cloud_last_sync_at IS NOT NULL)"
      t.index [:jira_dvcs_server_last_sync_at, :project_id], name: "idx_proj_feat_usg_on_jira_dvcs_server_last_sync_at_and_proj_id", where: "(jira_dvcs_server_last_sync_at IS NOT NULL)"
    end
  end
end
