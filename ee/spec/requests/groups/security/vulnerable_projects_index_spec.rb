# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /groups/*group_id/-/security/projects' do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(security_dashboard: true)
    login_as(user)

    group.add_developer(user)
  end

  it 'does not use N+1 queries' do
    control_project = create(:project, namespace: group)
    create(:vulnerabilities_occurrence, project: control_project)

    control_count = ActiveRecord::QueryRecorder.new do
      get group_security_vulnerable_projects_path(group, format: :json)
    end

    projects = create_list(:project, 2, namespace: group)

    projects.each do |project|
      ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.keys.each do |severity|
        create(:vulnerabilities_occurrence, severity: severity, project: project)
      end
    end

    expect do
      get group_security_vulnerable_projects_path(group, format: :json)
    end.not_to exceed_query_limit(control_count)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.size).to be(3)
  end
end
