# frozen_string_literal: true

module Projects
  class ThreatMonitoringController < Projects::ApplicationController
    before_action :authorize_read_threat_monitoring!
    before_action :verify_network_policy_editor_flag!, only: [:new, :edit]
    before_action do
      push_frontend_feature_flag(:network_policy_editor, project)
    end

    def edit
      @environment = project.environments.find(params[:environment_id])
      @policy_name = params[:id]
      response = NetworkPolicies::FindResourceService.new(
        resource_name: @policy_name,
        environment: @environment,
        kind: Gitlab::Kubernetes::CiliumNetworkPolicy::KIND
      ).execute

      if response.success?
        @policy = response.payload
      else
        render_404
      end
    end

    private

    def verify_network_policy_editor_flag!
      render_404 unless Feature.enabled?(:network_policy_editor, project, default_enabled: false)
    end
  end
end
