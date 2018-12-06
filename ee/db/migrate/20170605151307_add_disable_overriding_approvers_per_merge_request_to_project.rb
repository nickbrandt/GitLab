class AddDisableOverridingApproversPerMergeRequestToProject < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :projects, :disable_overriding_approvers_per_merge_request, :boolean
  end
end
