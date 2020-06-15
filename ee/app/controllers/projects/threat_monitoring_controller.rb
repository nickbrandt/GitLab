# frozen_string_literal: true

module Projects
  class ThreatMonitoringController < Projects::ApplicationController
    before_action :authorize_read_threat_monitoring!
  end
end
