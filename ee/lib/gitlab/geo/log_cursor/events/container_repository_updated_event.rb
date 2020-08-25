# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        class ContainerRepositoryUpdatedEvent
          include BaseEvent

          def process
            if should_sync?
              registry.repository_updated!

              job_id = ::Geo::ContainerRepositorySyncWorker.perform_async(event.container_repository_id)
            end

            log_event(job_id)
          end

          private

          def should_sync?
            strong_memoize(:should_sync) do
              ::Geo::ContainerRepositoryRegistry.replication_enabled? &&
                registry.container_repository &&
                replicable_project?(registry.container_repository.project_id)
            end
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def registry
            @registry ||= ::Geo::ContainerRepositoryRegistry.find_or_initialize_by(
              container_repository_id: event.container_repository_id
            )
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def log_event(job_id)
            super(
              'Docker Repository update',
              container_repository_id: registry.container_repository_id,
              should_sync: should_sync?,
              replication_enabled: ::Geo::ContainerRepositoryRegistry.replication_enabled?,
              replicable_project: replicable_project?(registry.container_repository.project_id),
              project_id: registry.container_repository.project_id,
              job_id: job_id)
          end
        end
      end
    end
  end
end
