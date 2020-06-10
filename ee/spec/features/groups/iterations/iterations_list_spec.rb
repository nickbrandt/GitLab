# frozen_string_literal: true

require 'spec_helper'

describe 'Iterations list', :js do
  let(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let!(:started_iteration) { create(:iteration, :skip_future_date_validation, group: group, start_date: now - 1.day, due_date: now) }
  let!(:upcoming_iteration) { create(:iteration, group: group, start_date: now + 1.day, due_date: now + 2.days) }
  let!(:closed_iteration) { create(:closed_iteration, :skip_future_date_validation, group: group, start_date: now - 3.days, due_date: now - 2.days) }

  context 'as guest' do
    before do
      visit group_iterations_path(group)
    end

    it 'hides New iteration button' do
      expect(page).not_to have_link('New iteration', href: new_group_iteration_path(group))
    end

    it 'shows iterations on each tab' do
      expect(page).to have_link(started_iteration.title)
      expect(page).to have_link(upcoming_iteration.title)
      expect(page).not_to have_link(closed_iteration.title)

      click_link('Closed')

      expect(page).to have_link(closed_iteration.title)
      expect(page).not_to have_link(started_iteration.title)
      expect(page).not_to have_link(upcoming_iteration.title)

      click_link('All')

      expect(page).to have_link(started_iteration.title)
      expect(page).to have_link(upcoming_iteration.title)
      expect(page).to have_link(closed_iteration.title)
    end
  end

  context 'as user' do
    before do
      stub_licensed_features(iterations: true)
      stub_feature_flags(group_iterations: true)
      group.add_developer(user)
      sign_in(user)
      visit group_iterations_path(group)
    end

    it 'shows "New iteration" button' do
      expect(page).to have_link('New iteration', href: new_group_iteration_path(group))
    end
  end
end
