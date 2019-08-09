# frozen_string_literal: true
require 'spec_helper'

describe 'Group Cycle Analytics', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, group: group) }

  before do
    group.add_owner(user)
    project.add_maintainer(user)

    sign_in(user)

    visit analytics_cycle_analytics_path
  end

  it 'displays an empty state before a group is selected' do
    element = page.find('.row.empty-state')

    expect(element).to have_content("Cycle Analytics can help you determine your team’s velocity")
    expect(element.find('.svg-content img')['src']).to have_content('illustrations/analytics/cycle-analytics-empty-chart')
  end

  context 'displays correct fields after group selection' do
    before do
      dropdown = page.find('.dropdown-groups')
      dropdown.click
      dropdown.find('a').click
    end

    it 'hides the empty state' do
      expect(page).to have_selector('.row.empty-state', visible: false)
    end

    it 'shows the projects filter' do
      expect(page).to have_selector('.dropdown-projects', visible: true)
    end

    it 'shows the date filter' do
      expect(page).to have_selector('.js-timeframe-filter', visible: true)
    end
  end
end
