# frozen_string_literal: true

module Geo
  class ContainerRepositorySyncService
    include ::Gitlab::Geo::ContainerRepositoryLogHelpers

    attr_reader :container_repository

    def initialize(container_repository)
      @container_repository = container_repository
    end

    def execute
      return unless Feature.enabled?(:geo_registry_replication)

      log_info('Marking sync as started')
      registry.start_sync!

      Geo::ContainerRepositorySync.new(container_repository).execute

      registry.finish_sync!
      log_info('Finished sync')
    rescue => e
      fail_registry_sync!("Container repository sync failed", e)
    end

    private

    def fail_registry_sync!(message, error)
      log_error(message, error)

      registry.fail_sync!(message, error)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def registry
      @registry ||= begin
        Geo::ContainerRepositoryRegistry.find_or_initialize_by(
          container_repository_id: container_repository.id
        )
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
