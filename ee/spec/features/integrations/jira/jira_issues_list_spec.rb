# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jira issues list' do
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_integration) { create(:jira_service, project: project, issues_enabled: true) }
  let(:user) { create(:user) }

  before do
    project.add_user(user, :developer)
    sign_in(user)
  end

  it 'renders "Create new issue" button' do
    visit project_integrations_jira_issues_path(project)

    expect(page).to have_link('Create new issue in Jira')
  end
end
