# frozen_string_literal: true

class UpdateExistingPublicProjectsInPrivateGroupsToPrivateProjects < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  PRIVATE = 0
  INTERNAL = 10
  MIGRATION = 'UpdateExistingPublicProjectsInPrivateGroupsToPrivateProjects'

  def up
    # Update project's visibility to be the same as the group
    # if it is more restrictive than `PUBLIC`.
    bulk_migrate_async(
      [
        [MIGRATION, [PRIVATE]],
        [MIGRATION, [INTERNAL]]
      ]
    )
  end

  def down
    # no-op: unrecoverable data migration
  end
end
