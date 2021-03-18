# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User sees empty state' do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:auditor) { create(:user, auditor: true) }

  context 'when signed in user is an Auditor' do
    before do
      sign_in(auditor)
    end

    it 'shows empty state without "New issue" button' do
      visit project_issues_path(project)

      expect(page).to have_content('The Issue Tracker is the place to add things that need to be improved or solved in a project')
      expect(page).to have_content('Issues can be bugs, tasks or ideas to be discussed. Also, issues are searchable and filterable.')
      expect(page).not_to have_link('New issue')
    end
  end
end
