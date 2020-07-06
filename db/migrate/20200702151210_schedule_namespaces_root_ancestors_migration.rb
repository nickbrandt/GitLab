# frozen_string_literal: true

class ScheduleNamespacesRootAncestorsMigration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 10_000
  MIGRATION = 'MigrateNamespacesRootAncestors'

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'namespaces'
  end

  def up
    say "Scheduling `#{MIGRATION}` jobs"

    # At the time of writing there are ~7_628_844 records to be iterated for GitLab.com,
    # batches of 10_000 with delay interval of 2 minutes gives us an estimate of close to 24 hours.
    queue_background_migration_jobs_by_range_at_intervals(Namespace, MIGRATION, 2.minutes, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
