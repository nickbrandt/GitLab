require 'spec_helper'

describe 'User views issue designs', :js do
  include DesignManagementTestHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    enable_design_management

    create(:design, :with_file, issue: issue, filename: 'world.png')

    visit project_issue_path(project, issue)

    click_link 'Designs'

    wait_for_requests
  end

  it 'opens design detail' do
    find('.js-design-list-item', match: :first).click

    page.within(find('.js-design-header')) do
      expect(page).to have_content('world.png')
    end

    expect(page).to have_selector('.js-design-image')
  end
end
