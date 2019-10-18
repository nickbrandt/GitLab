# frozen_string_literal: true

class ClearSharedRunnersMinutesWorker
  LEASE_TIMEOUT = 3600

  include ApplicationWorker
  include CronjobQueue

  feature_category :continuous_integration

  def perform
    return unless try_obtain_lease

    Namespace.with_shared_runners_minutes_limit
      .with_extra_shared_runners_minutes_limit
      .with_shared_runners_minutes_exceeding_default_limit
      .update_all("extra_shared_runners_minutes_limit = #{extra_minutes_left_sql} FROM namespace_statistics")

    Namespace.with_ci_minutes_notification_sent.each_batch do |namespaces|
      namespaces.update_all(last_ci_minutes_notification_at: nil, last_ci_minutes_usage_notification_level: nil)
    end

    Namespace.select(:id).each_batch do |namespaces|
      Namespace.transaction do
        reset_statistics(NamespaceStatistics, namespaces)
        reset_statistics(ProjectStatistics, namespaces)
      end
    end
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def reset_statistics(model, namespaces)
    model.where(namespace: namespaces).where.not(shared_runners_seconds: 0).update_all(
      shared_runners_seconds: 0,
      shared_runners_seconds_last_reset: Time.now)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def extra_minutes_left_sql
    "GREATEST((namespaces.shared_runners_minutes_limit + namespaces.extra_shared_runners_minutes_limit) - ROUND(namespace_statistics.shared_runners_seconds / 60.0), 0)"
  end

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_clear_shared_runners_minutes_worker',
      timeout: LEASE_TIMEOUT).try_obtain
  end
end
