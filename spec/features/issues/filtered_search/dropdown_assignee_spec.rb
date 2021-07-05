# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown assignee', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the assignees when opened' do
      select_tokens 'Assignee', '=', submit: false

      # Expect None, Any, administrator, John Doe2
      expect_filtered_search_suggestion_count 4
    end

    it 'shows current user at top of dropdown' do
      select_tokens 'Assignee', '=', submit: false

      # List items 1 to 3 are None, Any, divider
      expect(find('.gl-filtered-search-suggestion:nth-child(4)')).to have_text user.name
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      select_tokens 'Assignee', '=', submit: false
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      click_on user.username

      expect_assignee_token(user.username)
      expect_empty_search_term
    end
  end
end
