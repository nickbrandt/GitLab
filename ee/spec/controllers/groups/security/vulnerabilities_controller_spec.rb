# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::VulnerabilitiesController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  it_behaves_like VulnerabilitiesActions do
    let(:vulnerable) { group }
    let(:vulnerable_params) { { group_id: group } }
  end

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { group }
    let(:security_dashboard_action) { get :index, params: { group_id: group }, format: :json }
  end

  before do
    sign_in(user)
  end

  describe 'GET index.json' do
    it 'returns vulnerabilities for all projects in the group' do
      stub_licensed_features(security_dashboard: true)
      group.add_developer(user)

      # create projects for the group
      2.times do
        project = create(:project, namespace: group)
        pipeline = create(:ci_pipeline, :success, project: project)

        create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project, severity: :high)
      end

      # create an ungrouped project to ensure we don't include it
      project = create(:project)
      pipeline = create(:ci_pipeline, :success, project: project)
      create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project, severity: :high)

      get :index, params: { group_id: group }, format: :json

      expect(json_response.count).to be(2)
    end
  end
end
