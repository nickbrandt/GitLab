# frozen_string_literal: true

class ClearSharedRunnersMinutesWorker
  LEASE_TIMEOUT = 3600

  include ApplicationWorker
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  # all queries are scoped across multiple namespaces
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext
  feature_category :continuous_integration

  def perform
    return unless try_obtain_lease

    Namespace.reset_ci_minutes_in_batches!
  end

  private

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_clear_shared_runners_minutes_worker',
      timeout: LEASE_TIMEOUT).try_obtain
  end
end
