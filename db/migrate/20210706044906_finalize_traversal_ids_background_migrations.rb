# frozen_string_literal: true

class FinalizeTraversalIdsBackgroundMigrations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    finalize_background_migration('BackfillNamespaceTraversalIdsRoots', delete_tracking_jobs: true)
    finalize_background_migration('BackfillNamespaceTraversalIdsChildren', delete_tracking_jobs: true)
  end

  def down
    # no-op
  end
end
