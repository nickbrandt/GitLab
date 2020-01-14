# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddFieldsToApplicationSettingsForMergeRequestsApprovals < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :disable_overriding_approvers_per_merge_request,
                            :boolean,
                            default: false,
                            allow_null: false)
    add_column_with_default(:application_settings, :prevent_merge_requests_author_approval,
                            :boolean,
                            default: false,
                            allow_null: false)
    add_column_with_default(:application_settings, :prevent_merge_requests_committers_approval,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :disable_overriding_approvers_per_merge_request)
    remove_column(:application_settings, :prevent_merge_requests_author_approval)
    remove_column(:application_settings, :prevent_merge_requests_committers_approval)
  end
end
