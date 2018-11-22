class AddPullMirrorAvailableOverriddenToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :projects, :pull_mirror_available_overridden, :boolean
  end
end
