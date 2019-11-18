# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        class DesignRepositoryUpdatedEvent
          include BaseEvent

          def process
            job_id =
              unless skippable?
                registry.repository_updated!
                schedule_job(event)
              end

            log_event(job_id)
          end

          private

          def registry
            @registry ||= ::Geo::DesignRegistry.safe_find_or_create_by(project_id: event.project_id)
          end

          def schedule_job(event)
            enqueue_job_if_shard_healthy(event) do
              ::Geo::DesignRepositorySyncWorker.perform_async(event.project_id)
            end
          end

          def skippable?
            Feature.disabled?(:enable_geo_design_sync)
          end

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Design repository update',
              project_id: event.project_id,
              scheduled_at: Time.now,
              skippable: skippable?,
              job_id: job_id)
          end
        end
      end
    end
  end
end
