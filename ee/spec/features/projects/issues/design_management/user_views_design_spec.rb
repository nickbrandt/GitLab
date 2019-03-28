require 'spec_helper'

describe 'User views issue designs', :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    visit project_issue_path(project, issue)

    click_link 'Designs'

    wait_for_requests
  end

  it 'opens design detail' do
    first('.js-design-list-item').click

    page.within(find('.js-design-header')) do
      expect(page).to have_content('test.jpg')
      expect(page).to have_content('Test Name')
    end
  end
end
