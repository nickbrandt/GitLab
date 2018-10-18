# frozen_string_literal: true

class AddMissingGeoEvenLogIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEXED_COLUMNS = %i[cache_invalidation_event_id
                       repositories_changed_event_id
                       repository_created_event_id
                       repository_deleted_event_id
                       repository_renamed_event_id
                       repository_updated_event_id
                       reset_checksum_event_id]

  OTHER_COLUMNS = %i[hashed_storage_migrated_event_id
                     lfs_object_deleted_event_id
                     hashed_storage_attachments_event_id
                     job_artifact_deleted_event_id
                     upload_deleted_event_id]

  disable_ddl_transaction!

  def up
    # Remove existing indexes that aren't partial
    INDEXED_COLUMNS.each do |col|
      remove_concurrent_index(:geo_event_log, col)
    end

    # Create partial indexes on all
    (INDEXED_COLUMNS + OTHER_COLUMNS).each do |col|
      add_concurrent_index(:geo_event_log,
                           col,
                           where: "#{col} IS NOT NULL")
    end
  end

  def down
    # Rollback all partial indexes
    (INDEXED_COLUMNS + OTHER_COLUMNS).each do |col|
      remove_concurrent_index(:geo_event_log, col)
    end

    # Recreate full indexes
    INDEXED_COLUMNS.each do |col|
      add_concurrent_index(:geo_event_log, col)
    end
  end
end
