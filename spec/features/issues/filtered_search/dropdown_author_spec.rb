# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown author', :js do
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
    it 'loads all the authors when opened' do
      select_tokens 'Author', submit: false

      expect_filtered_search_suggestion_count 2
    end

    it 'shows current user at top of dropdown' do
      select_tokens 'Author', submit: false

      expect(find('.gl-filtered-search-suggestion:first-child')).to have_text user.name
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      select_tokens 'Author', submit: false
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      click_on user.username

      expect_author_token(user.username)
      expect_empty_search_term
    end
  end
end
