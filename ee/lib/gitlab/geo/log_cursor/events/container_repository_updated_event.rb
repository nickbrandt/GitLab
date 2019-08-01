# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        class ContainerRepositoryUpdatedEvent
          include BaseEvent

          def process
            return unless Feature.enabled?(:geo_registry_replication)

            registry.repository_updated!

            job_id = ::Geo::ContainerRepositorySyncWorker.perform_async(event.container_repository_id)

            log_event(job_id)
          end

          private

          def skippable?
            !!Gitlab.config.geo.registry_replication.enabled
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def registry
            @registry ||= ::Geo::ContainerRepositoryRegistry.find_or_initialize_by(
              container_repository_id: event.container_repository_id
            )
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Docker Repository update',
              container_repository_id: registry.container_repository_id,
              skippable: skippable?,
              project: registry.container_repository.project_id)
          end
        end
      end
    end
  end
end
