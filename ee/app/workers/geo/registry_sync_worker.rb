# frozen_string_literal: true

module Geo
  class RegistrySyncWorker
    include ApplicationWorker
    prepend Reenqueuer
    include GeoQueue
    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
    include ::Gitlab::Geo::LogHelpers

    idempotent!

    LEASE_TIMEOUT = 2.minutes

    attr_reader :pending_resources

    def initialize
      @pending_resources = []
    end

    def perform
      return unless Feature.enabled?(:geo_self_service_framework)
      return unless node_enabled?

      start_time = Time.now.utc

      begin
        schedule_jobs
      rescue => err
        log_error('Error', error: err.message)
        raise err
      ensure
        duration = Time.now.utc - start_time
        log_info('Finished', duration: duration)
      end
    end

    private

    def max_capacity
      # Transition-period-solution.
      # Explained in https://gitlab.com/gitlab-org/gitlab/-/issues/213872#note_336828581
      max(current_node.files_max_capacity / 4, 1)
    end

    def schedule_job(replicable_name, record_id)
      job_id = ::Geo::EventWorker.perform_async(replicable_name, :created, model_record_id: record_id)

      { record_id: record_id, replicable_name: replicable_name, job_id: job_id } if job_id
    end

    # Pools for new resources to be transferred
    #
    # @return [Array] resources to be transferred
    def load_pending_resources(batch_size:)
      resources = find_unsynced_jobs(batch_size: batch_size)
      remaining_capacity = batch_size - resources.count

      if remaining_capacity.zero?
        resources
      else
        resources + find_low_priority_jobs(batch_size: remaining_capacity)
      end
    end

    def schedule_jobs
      num_to_schedule = [max_capacity - scheduled_job_ids.size].min
      num_to_schedule = 0 if num_to_schedule < 0

      to_schedule = load_pending_resources(batch_size: num_to_schedule)
      scheduled = to_schedule.map { |args| schedule_job(*args) }.compact
      track_scheduled_jobs(scheduled)

      log_info('Jobs scheduled', enqueued: scheduled.length, capacity: num_to_schedule)
    end

    # Get a batch of unsynced resources, taking equal parts from each resource.
    #
    # @return [Array] job arguments of unsynced resources
    def find_unsynced_jobs(batch_size:)
      jobs = replicators.reduce([]) do |jobs, replicator|
        except_ids = scheduled_job_ids(replicator.replicable_name)

        jobs << replicator
                  .registry_class
                  .find_unsynced_jobs(batch_size: batch_size, except_ids: except_ids)
                  .map { |job| [replicator.replicable_name, job[replicator.model_foreign_key]] }
      end

      take_batch(*jobs, batch_size: batch_size)
    end

    # Get a batch of failed and synced-but-missing-on-primary resources, taking
    # equal parts from each resource.
    #
    # @return [Array] job arguments of low priority resources
    def find_low_priority_jobs(batch_size:)
      jobs = replicators.reduce([]) do |jobs, replicator|
        except_ids = scheduled_job_ids(replicator.replicable_name)

        jobs << replicator
                  .registry_class
                  .find_failed_jobs(batch_size: batch_size, except_ids: except_ids)
                  .map { |job| [replicator.replicable_name, job[replicator.model_foreign_key]] }
      end

      take_batch(*jobs, batch_size: batch_size)
    end

    def scheduled_job_ids(replicable_name)
      scheduled_jobs(replicable_name).map { |job| job[:record_id] }
    end

    def scheduled_jobs(replicable_name)
      # Placeholder
      # We don't suppport scheduled jobs tracking yet
      []
    end

    def track_scheduled_jobs(scheduled_jobs)
      # Placeholder
      # We don't suppport scheduled jobs tracking yet
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def replicators
      Gitlab::Geo::ReplicableModel.replicators.map { |replicator_name| replicator_name.constantize }
    end

    def node_enabled?
      Gitlab::Geo.current_node_enabled?
    end
  end
end
