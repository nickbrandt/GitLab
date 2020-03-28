# frozen_string_literal: true

require 'spec_helper'

describe 'Requirements list', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(requirements: true)
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when requirements exist for the project' do
    before do
      visit project_requirements_path(project)
    end

    it 'shows the requirements in the navigation sidebar' do
      expect(first('.nav-sidebar  .active a .nav-item-name')).to have_content('Requirements')
    end

    it 'shows requirements tabs for each status type' do
      page.within('.requirements-state-filters') do
        expect(page).to have_selector('li > a#state-opened')
        expect(find('li > a#state-opened')[:title]).to eq('Filter by requirements that are currently opened.')

        expect(page).to have_selector('li > a#state-archived')
        expect(find('li > a#state-archived')[:title]).to eq('Filter by requirements that are currently archived.')

        expect(page).to have_selector('li > a#state-all')
        expect(find('li > a#state-all')[:title]).to eq('Show all requirements.')
      end
    end

    it 'shows button "New requirement"' do
      page.within('.nav-controls') do
        expect(page).to have_selector('button.js-new-requirement')
        expect(find('button.js-new-requirement')).to have_content('New requirement')
      end
    end
  end
end
