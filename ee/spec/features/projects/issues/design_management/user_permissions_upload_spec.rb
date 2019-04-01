require 'spec_helper'

describe 'User design permissions', :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    stub_licensed_features(design_management: true)

    visit project_issue_path(project, issue)

    click_link 'Designs'

    wait_for_requests
  end

  it 'user does not have permissions to upload design' do
    expect(page).not_to have_field('design_file')
  end
end
