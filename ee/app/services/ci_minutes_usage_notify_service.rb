# frozen_string_literal: true

class CiMinutesUsageNotifyService < BaseService
  def execute
    return unless ::Gitlab.com?

    notify_on_total_usage
    notify_on_partial_usage
  end

  private

  def recipients
    namespace.user? ? [namespace.owner.email] : namespace.owners.pluck(:email) # rubocop:disable CodeReuse/ActiveRecord
  end

  def notify_on_total_usage
    return unless namespace.shared_runners_minutes_used? && namespace.last_ci_minutes_notification_at.nil?

    namespace.update_columns(last_ci_minutes_notification_at: Time.now)

    CiMinutesUsageMailer.notify(namespace.name, recipients).deliver_later
  end

  def notify_on_partial_usage
    return if namespace.shared_runners_minutes_used?
    return if namespace.last_ci_minutes_usage_notification_level == current_alert_level
    return if alert_levels.max < ci_minutes_percent_left

    namespace.update_columns(last_ci_minutes_usage_notification_level: current_alert_level)

    CiMinutesUsageMailer.notify_limit(namespace.name, recipients, current_alert_level).deliver_later
  end

  def namespace
    @namespace ||= project.shared_runners_limit_namespace
  end

  def ci_minutes_percent_left
    quota = namespace.actual_shared_runners_minutes_limit
    used = namespace.shared_runners_minutes.to_i
    minutes_left = quota - used

    return 0 if minutes_left <= 0

    (minutes_left.to_f * 100) / quota.to_f
  end

  def alert_levels
    @alert_levels ||= EE::Namespace::CI_USAGE_ALERT_LEVELS.sort
  end

  def current_alert_level
    @current_alert_level ||= alert_levels.find { |level| level >= ci_minutes_percent_left }
  end
end
