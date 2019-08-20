# frozen_string_literal: true

module Geo
  module Secondary
    class RepositoryBackfillWorker
      include ApplicationWorker
      include ExclusiveLeaseGuard
      include GeoQueue
      include ::Gitlab::Geo::LogHelpers
      include ::Gitlab::Utils::StrongMemoize

      LEASE_TIMEOUT = 60.minutes
      RUN_TIME = 60.minutes.to_i

      def initialize
        @scheduled_jobs = []
      end

      def perform(shard_name)
        @shard_name = shard_name
        @start_time = Time.now.utc
        @loops = 0

        unless Gitlab::Geo.geo_database_configured?
          log_info('Geo database not configured')
          return
        end

        unless Gitlab::Geo.secondary?
          log_info('Current node not a secondary')
          return
        end

        unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)
          log_info("Shard (#{shard_name}) is not healthy")
          return
        end

        try_obtain_lease do
          log_info('Repository backfilling started')
          reason = :unknown

          begin
            connection.send_query(unsynced_projects_ids.to_sql)
            connection.set_single_row_mode

            reason = loop do
              break :node_disabled unless node_enabled?
              break :over_time if over_time?
              break :lease_lost unless renew_lease!

              update_jobs_in_progress

              # This will stream the results one by one
              # until there are no more results to fetch.
              result = connection.get_result or break
              result.check
              result.each do |row|
                schedule_job(row['id'])
              end

              if over_capacity?
                sleep(1)
              end
            end
          rescue => error
            reason = :error
            log_error('Repository backfilling error', error)
            raise error
          ensure
            log_info('Repository backfilling finished', total_loops: loops, duration: Time.now.utc - start_time, reason: reason)
          end
        end
      end

      private

      attr_reader :shard_name, :start_time, :loops, :scheduled_jobs

      def base_log_data(message)
        super(message).merge(worker_metadata)
      end

      def lease_key
        @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
      end

      def lease_timeout
        LEASE_TIMEOUT
      end

      def worker_metadata
        { shard: shard_name }
      end

      def connection
        strong_memoize(:connection) do
          Geo::TrackingBase.connection.raw_connection
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def schedule_job(project_id)
        job_id = Geo::ProjectSyncWorker.perform_async(project_id, sync_repository: true, sync_wiki: true)

        if job_id
          @scheduled_jobs << { job_id: job_id }
          log_info("Repository scheduled for backfilling", project_id: project_id, job_id: job_id)
        else
          log_info("Repository could not be scheduled for backfilling", project_id: project_id)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def unsynced_projects_ids
        Geo::ProjectUnsyncedFinder
          .new(current_node: Gitlab::Geo.current_node, shard_name: shard_name)
          .execute
          .reorder(last_repository_updated_at: :desc)
          .select(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def update_jobs_in_progress
        scheduled_job_ids = scheduled_jobs.map { |data| data[:job_id] }
        status = Gitlab::SidekiqStatus.job_status(scheduled_job_ids)

        # SidekiqStatus returns an array of booleans: true if the job is still running, false otherwise.
        # For each entry, first use `zip` to make { job_id: 123 } -> [ { job_id: 123 }, bool ]
        # Next, filter out the jobs that have completed.
        @scheduled_jobs = @scheduled_jobs.zip(status).map { |(job, running)| job if running }.compact
      end

      def max_capacity
        healthy_count = Gitlab::ShardHealthCache.healthy_shard_count

        # If we don't have a count, that means that for some reason
        # RepositorySyncWorker stopped running/updating the cache. We might
        # be trying to shut down Geo while this job may still be running.
        return 0 unless healthy_count.to_i > 0

        capacity_per_shard = Gitlab::Geo.current_node.repos_max_capacity / healthy_count

        [1, capacity_per_shard.to_i].max
      end

      def node_enabled?
        # Only check every minute to avoid polling the DB excessively
        unless @last_enabled_check.present? && @last_enabled_check > 1.minute.ago
          @last_enabled_check = Time.now
          clear_memoization(:current_node_enabled)
        end

        strong_memoize(:current_node_enabled) do
          Gitlab::Geo.current_node_enabled?
        end
      end

      def run_time
        RUN_TIME
      end

      def over_capacity?
        scheduled_jobs.size >= max_capacity
      end

      def over_time?
        (Time.now.utc - start_time) >= run_time
      end
    end
  end
end
