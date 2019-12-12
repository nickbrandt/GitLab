# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::VulnerabilitiesController do
  let(:project) { create(:project) }
  let(:params) { { project_id: project, namespace_id: project.creator } }

  # when new Vulnerability Findings API is enabled, this controller is not
  # and its actions are "moved" to Projects::Security::VulnerabilityFindingsController

  it_behaves_like 'ProjectVulnerabilityFindingsActions disabled' do
    let(:vulnerable) { project }
    let(:vulnerable_params) { params }
  end

  it_behaves_like 'SecurityDashboardsPermissions disabled' do
    let(:vulnerable) { project }
    let(:security_dashboard_action) { get :index, params: params, format: :json }
  end

  context 'when new Vulnerability Findings API is disabled' do
    before do
      stub_feature_flags(first_class_vulnerabilities: false)
    end

    # when new Vulnerability Findings API is disabled, we fall back to this controller

    it_behaves_like ProjectVulnerabilityFindingsActions do
      let(:vulnerable) { project }
      let(:vulnerable_params) { params }
    end

    it_behaves_like SecurityDashboardsPermissions do
      let(:vulnerable) { project }
      let(:security_dashboard_action) { get :index, params: params, format: :json }
    end
  end
end
