# frozen_string_literal: true

module Projects
  class ThreatMonitoringController < Projects::ApplicationController
    before_action :authorize_read_threat_monitoring!
    before_action :verify_network_policy_editor_flag!, only: :new
    before_action do
      push_frontend_feature_flag(:network_policy_editor, project)
    end

    private

    def verify_network_policy_editor_flag!
      render_404 unless Feature.enabled?(:network_policy_editor, project, default_enabled: false)
    end
  end
end
