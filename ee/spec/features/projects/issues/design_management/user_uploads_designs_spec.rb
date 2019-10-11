# frozen_string_literal: true

require 'spec_helper'

describe 'User uploads new design', :js do
  include DesignManagementTestHelpers

  set(:project) { create(:project_empty_repo, :public) }
  set(:user) { project.owner }
  set(:issue) { create(:issue, project: project) }

  before do
    sign_in(user)
  end

  context "when the feature is available" do
    before do
      enable_design_management

      visit project_issue_path(project, issue)

      click_link 'Designs'

      wait_for_requests
    end

    it 'uploads design' do
      attach_file(:design_file, logo_fixture, make_visible: true)

      expect(page).to have_selector('.js-design-list-item', count: 1)

      within first('#designs-tab .card') do
        expect(page).to have_content('dk.png')
      end
    end
  end

  context 'when the feature is not available' do
    before do
      visit project_issue_path(project, issue)
    end

    it 'does not show the designs link' do
      expect(page).not_to have_link('Designs')
    end
  end

  def logo_fixture
    Rails.root.join('spec', 'fixtures', 'dk.png')
  end
end
