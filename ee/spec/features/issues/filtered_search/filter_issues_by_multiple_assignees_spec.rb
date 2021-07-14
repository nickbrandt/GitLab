# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter issues by multiple assignees', :js do
  include FilteredSearchHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project, author: user, assignees: [user2, user]) }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)

    sign_in(user)
    visit project_issues_path(project)
  end

  it 'filters issues by multiple assignees' do
    select_tokens 'Assignee', '=', user.username, 'Assignee', '=', user2.username

    expect_assignee_token(user.name)
    expect_assignee_token(user2.name)
    expect_empty_search_term

    expect_issues_list_count(1)
  end
end
