# frozen_string_literal: true

module Geo
  class ProjectSyncWorker
    include ApplicationWorker
    include GeoQueue
    include Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(project_id, options = {})
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)
      project = registry.project

      if project.nil?
        log_error("Couldn't find project, skipping syncing", project_id: project_id)
        return
      end

      shard_name = project.repository_storage
      unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)
        log_error("Project shard '#{shard_name}' is unhealthy, skipping syncing", project_id: project_id)
        return
      end

      options = extract_options(registry, options)

      sync_repository(registry, options)
      sync_wiki(registry, options)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def sync_repository(registry, options)
      return unless options[:sync_repository] && registry.resync_repository?

      Geo::RepositorySyncService.new(registry.project).execute
    end

    def sync_wiki(registry, options)
      return unless options[:sync_wiki] && registry.resync_wiki?

      Geo::WikiSyncService.new(registry.project).execute
    end

    def extract_options(registry, options)
      options.is_a?(Hash) ? options.symbolize_keys : backward_options(registry, options)
    end

    # Before GitLab 11.8 we used to pass the scheduled time instead of an options hash,
    # this method makes the job arguments backward compatible and
    # can be removed in any version after GitLab 12.0.
    def backward_options(registry, schedule_time)
      {
        sync_repository: registry.repository_sync_due?(schedule_time),
        sync_wiki: registry.wiki_sync_due?(schedule_time)
      }
    end
  end
end
