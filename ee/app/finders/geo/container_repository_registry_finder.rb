# frozen_string_literal: true

module Geo
  class ContainerRepositoryRegistryFinder < RegistryFinder
    def registry_count
      registry_class.count
    end
    alias_method :count_registry, :registry_count

    def count_synced
      registry_class.synced.count
    end

    def count_failed
      registry_class.failed.count
    end

    def find_registry_differences(range)
      source_ids = replicables.id_in(range).pluck_primary_key
      tracked_ids = registry_class.pluck_model_ids_in_range(range)

      untracked_ids = source_ids - tracked_ids
      unused_tracked_ids = tracked_ids - source_ids

      [untracked_ids, unused_tracked_ids]
    end

    # Returns Geo::ContainerRepositoryRegistry records that have never been synced.
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
      registry_class
        .never_synced
        .model_id_not_in(except_ids)
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_retryable_dirty_registries(batch_size:, except_ids: [])
      registry_class
        .failed
        .retry_due
        .model_id_not_in(except_ids)
        .order(Gitlab::Database.nulls_first_order(:last_synced_at))
        .limit(batch_size)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def replicables
      current_node.container_repositories
    end

    def registry_class
      Geo::ContainerRepositoryRegistry
    end
  end
end
