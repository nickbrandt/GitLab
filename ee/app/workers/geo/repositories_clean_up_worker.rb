# frozen_string_literal: true

module Geo
  class RepositoriesCleanUpWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard
    include GeoQueue
    include Gitlab::Geo::LogHelpers
    include Gitlab::ShellAdapter

    BATCH_SIZE = 250
    LEASE_TIMEOUT = 60.minutes

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(geo_node_id)
      # Prevent multiple Sidekiq workers from performing repositories clean up
      try_obtain_lease do
        geo_node = GeoNode.find(geo_node_id)
        break unless geo_node.selective_sync?

        Project.where.not(id: geo_node.projects).find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each do |project|
            clean_up_repositories(project)
          end
        end
      end
    rescue ActiveRecord::RecordNotFound => error
      log_error('Could not find Geo node, skipping repositories clean up', error, geo_node_id: geo_node_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def clean_up_repositories(project)
      job_id = ::Geo::RepositoryCleanupWorker.perform_async(project.id, project.name, project.disk_path, project.repository.storage)

      if job_id
        log_info('Repository clean up scheduled', project_id: project.id, shard: project.repository.storage, disk_path: project.disk_path, job_id: job_id)
      else
        log_error('Could not clean up repository', project_id: project.id, shard: project.repository.storage, disk_path: project.disk_path)
      end
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
