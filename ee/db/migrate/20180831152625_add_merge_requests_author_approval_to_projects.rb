# frozen_string_literal: true

class AddMergeRequestsAuthorApprovalToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :merge_requests_author_approval, :boolean
  end
end
