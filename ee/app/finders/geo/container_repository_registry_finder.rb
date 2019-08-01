# frozen_string_literal: true

module Geo
  class ContainerRepositoryRegistryFinder < RegistryFinder
    def count_syncable
      container_repositories.count
    end

    def count_synced
      registries_for_container_repositories
        .merge(Geo::ContainerRepositoryRegistry.synced).count
    end

    def count_failed
      registries_for_container_repositories
        .merge(Geo::ContainerRepositoryRegistry.failed).count
    end

    def count_registry
      Geo::ContainerRepositoryRegistry.count
    end

    # Find limited amount of non replicated container repositories.
    #
    # You can pass a list with `except_repository_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_repository_ids ids that will be ignored from the query
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_repository_ids: [])
      container_repositories
        .missing_container_repository_registry
        .id_not_in(except_repository_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_ids(batch_size:, except_repository_ids: [])
      Geo::ContainerRepositoryRegistry
        .failed
        .retry_due
        .repository_id_not_in(except_repository_ids)
        .limit(batch_size)
        .pluck_container_repository_key
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def container_repositories
      current_node.container_repositories
    end

    def registries_for_container_repositories
      container_repositories
        .inner_join_container_repository_registry
    end
  end
end
