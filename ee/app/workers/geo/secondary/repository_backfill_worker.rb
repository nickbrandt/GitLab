# frozen_string_literal: true

module Geo
  module Secondary
    class RepositoryBackfillWorker # rubocop:disable Scalability/IdempotentWorker
      include Geo::Secondary::BackfillWorker

      private

      attr_reader :scheduled_jobs

      def connection
        strong_memoize(:connection) { Geo::TrackingBase.connection.raw_connection }
      end

      def max_capacity
        # If we don't have a count, that means that for some reason
        # RepositorySyncWorker stopped running/updating the cache. We might
        # be trying to shut down Geo while this job may still be running.
        healthy_count = healthy_shard_count
        return 0 unless healthy_count > 0

        capacity_per_shard = Gitlab::Geo.current_node.repos_max_capacity / healthy_count

        [1, capacity_per_shard.to_i].max
      end

      def healthy_shard_count
        Gitlab::ShardHealthCache.healthy_shard_count.to_i
      end

      def over_capacity?
        scheduled_jobs.size >= max_capacity
      end

      def schedule_jobs
        log_info('Repository backfilling started')
        reason = :unknown

        begin
          connection.send_query("#{projects_ids_unsynced.to_sql};#{project_ids_updated_recently.to_sql}")
          connection.set_single_row_mode

          reason = loop do
            break :node_disabled unless node_enabled?
            break :over_time if over_time?
            break :lease_lost unless renew_lease!

            update_jobs_in_progress

            if over_capacity?
              sleep(1)
            else
              # This will stream the results one by one
              # until there are no more results to fetch.
              result = connection.get_result
              break :complete if result.nil?

              result.check
              result.each do |row|
                schedule_job(row['id'])
              end
            end
          end
        rescue => error
          reason = :error
          log_error('Repository backfilling error', error)
          raise error
        ensure
          log_info('Repository backfilling finished', total_loops: loops, duration: Time.current.utc - start_time, reason: reason)
        end
      end

      def schedule_job(project_id)
        job_id = Geo::ProjectSyncWorker.perform_async(project_id, sync_repository: true, sync_wiki: true)

        if job_id
          @scheduled_jobs << { job_id: job_id }
          log_info("Repository scheduled for backfilling", project_id: project_id, job_id: job_id)
        else
          log_info("Repository could not be scheduled for backfilling", project_id: project_id)
        end
      end

      def scheduled_job_ids
        scheduled_jobs.map { |data| data[:job_id] }
      end

      def update_jobs_in_progress
        job_ids = scheduled_job_ids
        return if job_ids.empty?

        # SidekiqStatus returns an array of booleans: true if the job is still running, false otherwise.
        # For each entry, first use `zip` to make { job_id: 123 } -> [ { job_id: 123 }, bool ]
        # Next, filter out the jobs that have completed.
        @scheduled_jobs = Gitlab::SidekiqStatus.job_status(scheduled_job_ids).then do |status|
          @scheduled_jobs.zip(status).map { |(job, running)| job if running }.compact
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def projects_ids_unsynced
        Geo::ProjectUnsyncedFinder
          .new(current_node: Gitlab::Geo.current_node, shard_name: shard_name)
          .execute
          .reorder(last_repository_updated_at: :desc)
          .select(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def project_ids_updated_recently
        Geo::ProjectUpdatedRecentlyFinder
          .new(current_node: Gitlab::Geo.current_node, shard_name: shard_name)
          .execute
          .order('project_registry.last_repository_synced_at ASC NULLS FIRST, projects.last_repository_updated_at ASC')
          .select(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
