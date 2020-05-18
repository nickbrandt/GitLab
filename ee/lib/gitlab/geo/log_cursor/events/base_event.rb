# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        module BaseEvent
          include Utils::StrongMemoize

          def initialize(event, created_at, logger)
            @event = event
            @created_at = created_at
            @logger = logger
          end

          private

          attr_reader :event, :created_at, :logger

          # rubocop: disable CodeReuse/ActiveRecord
          def registry
            @registry ||= ::Geo::ProjectRegistry.find_or_initialize_by(project_id: event.project_id)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def skippable?
            registry.new_record?
          end

          def healthy_shard_for?(event)
            return true unless event.respond_to?(:project)

            Gitlab::ShardHealthCache.healthy_shard?(event.project.repository_storage)
          end

          def enqueue_job_if_shard_healthy(event)
            yield if healthy_shard_for?(event)
          end

          def log_event(message, params = {})
            logger.event_info(
              created_at,
              message,
              params.merge(event_id: event.id)
            )
          end
        end
      end
    end
  end
end
