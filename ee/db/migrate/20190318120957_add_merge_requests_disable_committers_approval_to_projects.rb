# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMergeRequestsDisableCommittersApprovalToProjects < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :projects, :merge_requests_disable_committers_approval, :boolean
  end
end
