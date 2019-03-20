# frozen_string_literal: true

require 'spec_helper'

describe 'Issue weight' do
  let(:project) { create(:project, :public) }

  it 'shows weight on issue list row' do
    create(:issue, project: project, weight: 2)

    visit project_issues_path(project)

    page.within(first('.issuable-info')) do
      expect(page).to have_selector('.issue-weight-icon')
      expect(page).to have_content(2)
    end
  end

  it 'allows user to update weight', :js do
    user = create(:user)
    issue = create(:issue, author: user, project: project)

    project.add_developer(user)
    sign_in(user)

    visit project_issue_path(project, issue)

    page.within('.weight') do
      expect(page).to have_content "None"

      click_link 'Edit'

      find('.block.weight input').send_keys 1, :enter

      page.within('.value') do
        expect(page).to have_content "1"
      end
    end
  end
end
