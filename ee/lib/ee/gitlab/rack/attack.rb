# frozen_string_literal: true

module EE::Gitlab::Rack::Attack
  Rack::Attack.throttle('throttle_incident_management_notification_web', EE::Gitlab::Throttle.incident_management_options) do |req|
    EE::Gitlab::Throttle.settings.throttle_incident_management_notification_enabled &&
      req.web_request? &&
      req.path.include?('alerts/notify') &&
      req.path
  end
end
