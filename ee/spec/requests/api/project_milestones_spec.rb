# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectMilestones do
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }
  let(:issues_route) { "/projects/#{project.id}/milestones/#{milestone.id}/issues" }

  before do
    project.add_developer(user)
    milestone.issues << create(:issue, project: project)
  end

  it 'matches V4 EE-specific response schema for a list of issues' do
    get api(issues_route, user)

    expect(response).to have_gitlab_http_status(200)
    expect(response).to match_response_schema('public_api/v4/issues', dir: 'ee')
  end
end
