# frozen_string_literal: true

class CiMinutesUsageNotifyService < BaseService
  def execute
    return unless namespace.shared_runners_minutes_used? && namespace.last_ci_minutes_notification_at.nil?

    namespace.update_columns(last_ci_minutes_notification_at: Time.now)

    owners.each do |user|
      CiMinutesUsageMailer.notify(namespace.name, user.email).deliver_later
    end
  end

  private

  def namespace
    @namespace ||= project.shared_runners_limit_namespace
  end

  def owners
    namespace.user? ? [namespace.owner] : namespace.owners
  end
end
