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

  it 'fetches list of designs' do
    expect(page).to have_selector('.js-design-list-item', count: 1)
  end
end
