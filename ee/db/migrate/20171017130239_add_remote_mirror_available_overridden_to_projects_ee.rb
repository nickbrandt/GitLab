class AddRemoteMirrorAvailableOverriddenToProjectsEE < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # When moving from CE to EE, this column may already exist
    return if column_exists?(:projects, :remote_mirror_available_overridden)

    add_column(:projects, :remote_mirror_available_overridden, :boolean)
  end

  def down
    remove_column(:projects, :remote_mirror_available_overridden)
  end
end
