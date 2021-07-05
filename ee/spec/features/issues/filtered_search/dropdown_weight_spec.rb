# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown weight', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the weights when opened' do
      select_tokens 'Weight', '=', submit: false

      # Expect None, Any, numbers 0 to 20
      expect_filtered_search_suggestion_count 23
    end
  end
end
