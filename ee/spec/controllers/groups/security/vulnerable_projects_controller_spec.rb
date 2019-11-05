# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::VulnerableProjectsController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { group }
    let(:security_dashboard_action) { get :index, params: { group_id: group }, format: :json }
  end

  describe '#index' do
    before do
      stub_licensed_features(security_dashboard: true)

      group.add_developer(user)
      sign_in(user)
    end

    subject { get :index, params: { group_id: group }, format: :json }

    it "responds with a list of the group's most vulnerable projects" do
      _ungrouped_project = create(:project)
      _safe_project = create(:project, namespace: group)
      vulnerable_project = create(:project, namespace: group)
      create_list(:vulnerabilities_occurrence, 2, project: vulnerable_project, severity: :critical)

      subject

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.count).to be(1)
      expect(json_response.first['id']).to eq(vulnerable_project.id)
      expect(json_response.first['full_path']).to eq(project_path(vulnerable_project))
      expect(json_response.first['critical_vulnerability_count']).to eq(2)
    end

    it 'does not include archived or deleted projects' do
      archived_project = create(:project, :archived, namespace: group)
      deleted_project = create(:project, namespace: group, pending_delete: true)
      create(:vulnerabilities_occurrence, project: archived_project)
      create(:vulnerabilities_occurrence, project: deleted_project)

      subject

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_empty
    end
  end
end
