# frozen_string_literal: true

class AddUniqueIndexesForBatchedBackgroundMigrations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION_INDEX_NAME = 'unique_nonaborted_background_migrations_on_job_table_and_args'
  JOB_INDEX_NAME = 'unique_jobs_per_batched_migration_and_starting_value'

  disable_ddl_transaction!

  def change
    add_concurrent_index :batched_background_migrations,
      %i[job_class_name table_name column_name job_arguments],
      unique: true,
      where: 'status <> 2',
      name: MIGRATION_INDEX_NAME

    add_concurrent_index :batched_background_migration_jobs,
      %i[batched_background_migration_id min_value],
      unique: true,
      name: JOB_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :batched_background_migration_jobs, JOB_INDEX_NAME

    remove_concurrent_index_by_name :batched_background_migrations, MIGRATION_INDEX_NAME
  end
end
