# frozen_string_literal: true

class UpdateAllMirrorsWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :source_code_management

  LEASE_TIMEOUT = 5.minutes
  SCHEDULE_WAIT_TIMEOUT = 4.minutes
  LEASE_KEY = 'update_all_mirrors'.freeze
  RESCHEDULE_WAIT = 1.second

  def perform
    return if Gitlab::Database.read_only?

    Gitlab::ApplicationContext.with_context({ user: nil, project: nil, namespace: nil }) do
      scheduled = 0
      with_lease do
        scheduled = schedule_mirrors!
      end

      # If we didn't get the lease, or no updates were scheduled, exit early
      break unless scheduled > 0

      # Wait to give some jobs a chance to complete
      Kernel.sleep(RESCHEDULE_WAIT)

      # If there's capacity left now (some jobs completed),
      # reschedule this job to enqueue more work.
      #
      # This is in addition to the regular (cron-like) scheduling of this job.
      UpdateAllMirrorsWorker.perform_async if Gitlab::Mirror.reschedule_immediately?
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def schedule_mirrors!
    capacity = Gitlab::Mirror.available_capacity

    # Ignore mirrors that become due for scheduling once work begins, so we
    # can't end up in an infinite loop
    now = Time.now
    last = nil
    scheduled = 0

    while capacity > 0
      batch_size = [capacity * 2, 500].min
      projects = pull_mirrors_batch(freeze_at: now, batch_size: batch_size, offset_at: last).to_a
      break if projects.empty?

      project_ids = projects.lazy.select(&:mirror?).take(capacity).map(&:id).force
      capacity -= project_ids.length

      ProjectImportScheduleWorker.bulk_perform_async(project_ids.map { |id| [id] })
      scheduled += project_ids.length

      # If fewer than `batch_size` projects were returned, we don't need to query again
      break if projects.length < batch_size

      last = projects.last.import_state.next_execution_timestamp
    end

    if scheduled > 0
      # Wait for all ProjectImportScheduleWorker jobs to complete
      deadline = Time.now + SCHEDULE_WAIT_TIMEOUT
      sleep 1 while ProjectImportScheduleWorker.queue_size > 0 && Time.now < deadline
    end

    scheduled
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def with_lease
    if lease_uuid = try_obtain_lease
      yield
    end

    lease_uuid
  ensure
    cancel_lease(lease_uuid) if lease_uuid
  end

  def try_obtain_lease
    ::Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT).try_obtain
  end

  def cancel_lease(uuid)
    ::Gitlab::ExclusiveLease.cancel(LEASE_KEY, uuid)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def pull_mirrors_batch(freeze_at:, batch_size:, offset_at: nil)
    relation = Project
      .mirrors_to_sync(freeze_at)
      .reorder('import_state.next_execution_timestamp')
      .limit(batch_size)
      .includes(:namespace) # Used by `project.mirror?`

    relation = relation.where('import_state.next_execution_timestamp > ?', offset_at) if offset_at

    relation
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
