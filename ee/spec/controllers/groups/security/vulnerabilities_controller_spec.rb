# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::VulnerabilitiesController do
  let(:group) { create(:group) }
  let(:params) { { group_id: group } }
  let(:user) { create(:user) }

  # when new Vulnerability Findings API is enabled this controller is not,
  # its actions are "moved" Groups::Security::VulnerabilityFindingsController

  it_behaves_like 'ProjectVulnerabilityFindingsActions disabled' do
    let(:vulnerable) { group }
    let(:vulnerable_params) { params }
  end

  it_behaves_like 'SecurityDashboardsPermissions disabled' do
    let(:vulnerable) { group }
    let(:security_dashboard_action) { get :index, params: params, format: :json }
  end

  it_behaves_like 'disabled group vulnerability findings controller'

  context 'when new Vulnerability Findings API is disabled' do
    before do
      stub_feature_flags(first_class_vulnerabilities: false)
    end

    # when new Vulnerability Findings API is disabled, we fall back to this controller

    it_behaves_like ProjectVulnerabilityFindingsActions do
      let(:vulnerable) { group }
      let(:vulnerable_params) { params }
    end

    it_behaves_like SecurityDashboardsPermissions do
      let(:vulnerable) { group }
      let(:security_dashboard_action) { get :index, params: params, format: :json }
    end

    it_behaves_like 'group vulnerability findings controller'
  end
end
