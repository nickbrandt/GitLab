# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /-/security/vulnerable_projects' do
  it_behaves_like 'security dashboard JSON endpoint' do
    let(:security_dashboard_request) do
      get security_vulnerable_projects_path, headers: { 'ACCEPT' => 'application/json' }
    end
  end

  context 'with an authenticated user' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    before do
      stub_licensed_features(security_dashboard: true)

      project.add_developer(user)
      user.security_dashboard_projects << project

      login_as(user)
    end

    subject { get security_vulnerable_projects_path, headers: { 'ACCEPT' => 'application/json' } }

    it "responds with the projects on the user's dashboard and their vulnerability counts" do
      safe_project = create(:project)
      safe_project.add_developer(user)
      user.security_dashboard_projects << safe_project

      pipeline = create(:ci_pipeline, :success, project: project)
      create_list(
        :vulnerabilities_occurrence,
        2,
        pipelines: [pipeline],
        project: project,
        severity: :critical
      )

      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.count).to be(1)
      expect(json_response.first['id']).to eq(project.id)
      expect(json_response.first['full_path']).to eq(project_path(project))
      expect(json_response.first['critical_vulnerability_count']).to eq(2)
    end

    it 'does not include archived or deleted projects' do
      archived_project = create(:project, :archived)
      deleted_project = create(:project, pending_delete: true)
      archived_pipeline = create(:ci_pipeline, :success, project: archived_project)
      deleted_pipeline = create(:ci_pipeline, :success, project: deleted_project)
      create(:vulnerabilities_occurrence, pipelines: [archived_pipeline], project: archived_project)
      create(:vulnerabilities_occurrence, pipelines: [deleted_pipeline], project: deleted_project)
      archived_project.add_developer(user)
      deleted_project.add_developer(user)
      user.security_dashboard_projects << [archived_project, deleted_project]

      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
    end
  end
end
