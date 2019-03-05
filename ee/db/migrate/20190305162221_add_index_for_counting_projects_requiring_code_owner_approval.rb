# frozen_string_literal: true

class AddIndexForCountingProjectsRequiringCodeOwnerApproval < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX = [
    :projects, [:archived, :pending_delete, :merge_requests_require_code_owner_approval],
    name: 'projects_requiring_code_owner_approval',
    where: "pending_delete = 'f' AND archived = 'f' AND merge_requests_require_code_owner_approval = 't' "
  ]

  disable_ddl_transaction!

  def up
    add_concurrent_index(*INDEX)
  end

  def down
    remove_concurrent_index(*INDEX)
  end
end
