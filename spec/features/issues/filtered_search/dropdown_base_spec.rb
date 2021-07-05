# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown base', :js do
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
    it 'shows loading indicator when opened' do
      slow_requests do
        select_tokens 'Assignee', '=', submit: false

        expect(page).to have_css '[data-testid="filtered-search"] .gl-spinner'
      end
    end

    it 'hides loading indicator when loaded' do
      select_tokens 'Assignee', '=', submit: false

      expect(page).not_to have_css '[data-testid="filtered-search"] .gl-spinner'
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      select_tokens 'Assignee', '=', submit: false
      initial_size = filtered_search_suggestion_size

      expect(initial_size).to be > 0

      new_user = create(:user)
      project.add_maintainer(new_user)
      click_button 'Clear'

      select_tokens 'Assignee', '=', submit: false

      expect(filtered_search_suggestion_size).to eq(initial_size)
    end
  end
end
