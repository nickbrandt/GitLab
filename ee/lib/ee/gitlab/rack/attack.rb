# frozen_string_literal: true

module EE::Gitlab::Throttle
  def self.settings
    Gitlab::Throttle.settings
  end

  def self.incident_management_options
    limit_proc = proc { |req| settings.throttle_incident_management_notification_per_period }
    period_proc = proc { |req| settings.throttle_incident_management_notification_period_in_seconds.seconds }

    { limit: limit_proc, period: period_proc }
  end
end

module EE::Gitlab::Rack::Attack
  Rack::Attack.throttle('throttle_incident_management_notification_web', EE::Gitlab::Throttle.incident_management_options) do |req|
    EE::Gitlab::Throttle.settings.throttle_incident_management_notification_enabled &&
      req.web_request? &&
      req.path.include?('alerts/notify') &&
      req.path
  end
end
