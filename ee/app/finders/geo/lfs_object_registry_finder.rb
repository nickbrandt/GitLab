# frozen_string_literal: true

module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    def count_syncable
      syncable.count
    end

    def count_synced
      lfs_objects_synced.count
    end

    def count_failed
      lfs_objects_failed.count
    end

    def count_synced_missing_on_primary
      lfs_objects_synced_missing_on_primary.count
    end

    def count_registry
      Geo::FileRegistry.lfs_objects.count
    end

    def syncable
      if use_legacy_queries_for_selective_sync?
        legacy_finder.syncable
      elsif selective_sync?
        fdw_geo_node.lfs_objects.syncable
      else
        LfsObject.syncable
      end
    end

    # Find limited amount of non replicated lfs objects.
    #
    # You can pass a list with `except_file_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_file_ids ids that will be ignored from the query
    # rubocop:disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries_for_selective_sync?
          legacy_finder.lfs_objects_unsynced(except_file_ids: except_file_ids)
        else
          lfs_objects_unsynced(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries_for_selective_sync?
          legacy_finder.lfs_objects_migrated_local(except_file_ids: except_file_ids)
        else
          lfs_objects_migrated_local(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_file_ids: [])
      registries_for_lfs_objects
        .merge(Geo::FileRegistry.failed)
        .merge(Geo::FileRegistry.retry_due)
        .file_id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_file_ids: [])
      registries_for_lfs_objects
        .synced
        .missing_on_primary
        .retry_due
        .file_id_not_in(except_file_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    # rubocop:disable CodeReuse/Finder
    def legacy_finder
      @legacy_finder ||= Geo::LegacyLfsObjectRegistryFinder.new(current_node: current_node)
    end
    # rubocop:enable CodeReuse/Finder

    def fdw_geo_node
      @fdw_geo_node ||= Geo::Fdw::GeoNode.find(current_node.id)
    end

    def registries_for_lfs_objects
      if use_legacy_queries_for_selective_sync?
        legacy_finder.registries_for_lfs_objects
      else
        fdw_geo_node.lfs_object_registries
      end
    end

    def lfs_objects_synced
      if use_legacy_queries_for_selective_sync?
        legacy_finder.lfs_objects_synced
      else
        fdw_geo_node.lfs_objects.synced
      end
    end

    def lfs_objects_failed
      if use_legacy_queries_for_selective_sync?
        legacy_finder.lfs_objects_failed
      else
        fdw_geo_node.lfs_objects.failed
      end
    end

    def lfs_objects_unsynced(except_file_ids:)
      fdw_geo_node
        .lfs_objects
        .syncable
        .missing_file_registry
        .id_not_in(except_file_ids)
    end

    def lfs_objects_migrated_local(except_file_ids:)
      fdw_geo_node
        .lfs_objects
        .inner_join_file_registry
        .with_files_stored_remotely
        .id_not_in(except_file_ids)
    end

    def lfs_objects_synced_missing_on_primary
      if use_legacy_queries_for_selective_sync?
        legacy_finder.lfs_objects_synced_missing_on_primary
      else
        fdw_geo_node.lfs_objects.synced.missing_on_primary
      end
    end
  end
end
