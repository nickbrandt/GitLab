# frozen_string_literal: true

class ClearSharedRunnersMinutesWorker
  LEASE_TIMEOUT = 3600

  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    return unless try_obtain_lease

    if Gitlab::Database.postgresql?
      # Using UPDATE with a joined table is not supported in MySql
      Namespace.with_shared_runners_minutes_limit
        .with_extra_shared_runners_minutes_limit
        .where('namespace_statistics.namespace_id = namespaces.id')
        .where('namespace_statistics.shared_runners_seconds > (namespaces.shared_runners_minutes_limit * 60)')
        .update_all("extra_shared_runners_minutes_limit = #{extra_minutes_left_sql} FROM namespace_statistics")
    end

    Namespace.where('last_ci_minutes_notification_at IS NOT NULL OR last_ci_minutes_usage_notification_level IS NOT NULL')
      .each_batch do |relation|
      relation.update_all(last_ci_minutes_notification_at: nil, last_ci_minutes_usage_notification_level: nil)
    end

    NamespaceStatistics.where.not(shared_runners_seconds: 0)
      .update_all(
        shared_runners_seconds: 0,
        shared_runners_seconds_last_reset: Time.now)

    ProjectStatistics.where.not(shared_runners_seconds: 0)
      .update_all(
        shared_runners_seconds: 0,
        shared_runners_seconds_last_reset: Time.now)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def extra_minutes_left_sql
    "GREATEST((namespaces.shared_runners_minutes_limit + namespaces.extra_shared_runners_minutes_limit) - ROUND(namespace_statistics.shared_runners_seconds / 60.0), 0)"
  end

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_clear_shared_runners_minutes_worker',
      timeout: LEASE_TIMEOUT).try_obtain
  end
end
