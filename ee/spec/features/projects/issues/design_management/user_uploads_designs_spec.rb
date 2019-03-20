require 'spec_helper'

describe 'User uploads new design', :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    visit project_issue_path(project, issue)

    click_link 'Designs'

    wait_for_requests
  end

  it 'uploads design' do
    attach_file(:design_file, logo_fixture, make_visible: true)

    expect(page).to have_selector('.js-design-list-item', count: 6)

    within first('#designs-tab .card') do
      expect(page).to have_content('dk.png')
      expect(page).to have_content('Updated just now')
    end
  end

  def logo_fixture
    Rails.root.join('spec', 'fixtures', 'dk.png')
  end
end
