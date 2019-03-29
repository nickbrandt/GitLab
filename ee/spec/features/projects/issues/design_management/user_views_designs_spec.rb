require 'spec_helper'

describe 'User views issue designs', :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    stub_licensed_features(design_management: true)

    visit project_issue_path(project, issue)

    click_link 'Designs'

    wait_for_requests
  end

  it 'fetches list of designs' do
    expect(page).to have_selector('.js-design-list-item', count: 5)
  end
end
