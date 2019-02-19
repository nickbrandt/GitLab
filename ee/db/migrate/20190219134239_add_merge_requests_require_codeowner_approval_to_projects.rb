# frozen_string_literal: true

class AddMergeRequestsRequireCodeownerApprovalToProjects < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :merge_requests_require_code_owner_approval, :boolean
  end
end
