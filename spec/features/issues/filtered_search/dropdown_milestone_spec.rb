# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown milestone', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let_it_be(:uppercase_milestone) { create(:milestone, title: 'CAP_MILESTONE', project: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the milestones when opened' do
      select_tokens 'Milestone', '=', submit: false

      expect_filtered_search_suggestion_count 2
    end
  end
end
