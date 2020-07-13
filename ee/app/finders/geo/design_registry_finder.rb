# frozen_string_literal: true

module Geo
  class DesignRegistryFinder < RegistryFinder
    def count_syncable
      current_node(fdw: false).designs.count
    end

    def count_synced
      registries.merge(Geo::DesignRegistry.synced).count
    end

    def count_failed
      registries.merge(Geo::DesignRegistry.failed).count
    end

    def count_registry
      registries.count
    end

    def find_registry_differences(range)
      source_ids = Gitlab::Geo.current_node.designs.id_in(range).pluck_primary_key
      tracked_ids = Geo::DesignRegistry.pluck_model_ids_in_range(range)

      untracked_ids = source_ids - tracked_ids
      unused_tracked_ids = tracked_ids - source_ids

      [untracked_ids, unused_tracked_ids]
    end

    # Returns Geo::DesignRegistry records that have never been synced.
    #
    # Does not care about selective sync, because it considers the Registry
    # table to be the single source of truth. The contract is that other
    # processes need to ensure that the table only contains records that should
    # be synced.
    #
    # Any registries that have ever been synced that currently need to be
    # resynced will be handled by other find methods (like
    # #find_retryable_dirty_registries)
    #
    # You can pass a list with `except_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    # rubocop:disable CodeReuse/ActiveRecord
    def find_never_synced_registries(batch_size:, except_ids: [])
      Geo::DesignRegistry
        .never_synced
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_dirty_registries(batch_size:, except_ids: [])
      Geo::DesignRegistry
        .updated_recently
        .model_id_not_in(except_ids)
        .order(Gitlab::Database.nulls_first_order(:last_synced_at))
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def registries
      if Geo::DesignRegistry.registry_consistency_worker_enabled?
        Geo::DesignRegistry.all
      else
        current_node(fdw: true)
          .projects
          .with_designs
          .inner_join_design_registry
      end
    end
  end
end
