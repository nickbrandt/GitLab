# frozen_string_literal: true

class SchedulePopulateSchedulingTypeOnCiBuilds < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  def up
    migration = Gitlab::BackgroundMigration::PopulateSchedulingTypeOnCiBuilds
    migration_name = migration.to_s.demodulize
    relation = migration::Build.builds_to_update

    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          migration_name,
                                                          5.minutes,
                                                          batch_size: BATCH_SIZE)
  end

  def down
  end
end
