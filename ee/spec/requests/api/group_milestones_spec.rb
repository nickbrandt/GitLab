# frozen_string_literal: true

require 'spec_helper'

describe API::GroupMilestones do
  let(:user) { create(:user) }
  let(:group) { create(:group, :private) }
  let(:project) { create(:project, namespace: group) }
  let!(:group_member) { create(:group_member, group: group, user: user) }
  let!(:closed_milestone) { create(:closed_milestone, group: group, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, group: group, title: 'version2', description: 'open milestone') }
  let(:issues_route) { "/groups/#{group.id}/milestones/#{milestone.id}/issues" }

  before do
    project.add_developer(user)
    milestone.issues << create(:issue, project: project)
  end

  it 'matches V4 EE-specific  response schema for a list of issues' do
    get api(issues_route, user)

    expect(response).to have_gitlab_http_status(200)
    expect(response).to match_response_schema('public_api/v4/issues', dir: 'ee')
  end
end
