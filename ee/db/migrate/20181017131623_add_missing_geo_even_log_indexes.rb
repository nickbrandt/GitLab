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

  NON_INDEXED_COLUMNS = %i[hashed_storage_migrated_event_id
                           lfs_object_deleted_event_id
                           hashed_storage_attachments_event_id
                           job_artifact_deleted_event_id
                           upload_deleted_event_id]

  disable_ddl_transaction!

  def up
    # Replace existing indexes with partial indexes
    INDEXED_COLUMNS.each do |col|
      without_foreign_key(:geo_event_log, col) do
        remove_concurrent_index(:geo_event_log, col)
        add_concurrent_index_not_null(:geo_event_log, col)
      end
    end

    # Create partial indexes on non-indexed columns
    NON_INDEXED_COLUMNS.each do |col|
      add_concurrent_index_not_null(:geo_event_log, col)
    end
  end

  def down
    # Drop indexes that didn't exist before
    NON_INDEXED_COLUMNS.each do |col|
      without_foreign_key(:geo_event_log, col) do
        remove_concurrent_index(:geo_event_log, col)
      end
    end

    # Recreate full indexes
    INDEXED_COLUMNS.each do |col|
      without_foreign_key(:geo_event_log, col) do
        remove_concurrent_index(:geo_event_log, col)
        add_concurrent_index(:geo_event_log, col)
      end
    end
  end

  private

  def add_concurrent_index_not_null(table, col)
    add_concurrent_index(table, col, where: "#{col} IS NOT NULL")
  end

  def without_foreign_key(table, col)
    return yield unless drop_foreign_key?(table, col)

    begin
      remove_foreign_key(table, column: col)
      yield
    ensure
      add_concurrent_foreign_key(table, foreign_table_name(col), column: col, on_delete: :cascade)
    end
  end

  def drop_foreign_key?(table, col)
    Gitlab::Database.mysql? && foreign_key_exists?(table, column: col)
  end

  def foreign_table_name(col)
    ('geo_' + col.to_s.sub(/_id$/, '')).pluralize
  end
end
