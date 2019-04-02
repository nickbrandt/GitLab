# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDesignIdFromDesignVersions < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_foreign_key :design_management_versions, :design_management_designs
    remove_column(:design_management_versions, :design_management_design_id)
  end

  def down
    add_column(:design_management_versions, :design_management_design_id, :bigint)
    add_concurrent_foreign_key :design_management_versions, :design_management_designs, column: :design_management_design_id
  end
end
