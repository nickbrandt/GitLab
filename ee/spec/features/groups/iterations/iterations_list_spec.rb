# frozen_string_literal: true

require 'spec_helper'

describe 'Iterations list', :js do  
  let(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let!(:started_group_sprint) { create(:sprint, :skip_future_date_validation, group: group, title: 'one test', start_date: now - 1.day, due_date: now) }
  let!(:upcoming_group_sprint) { create(:sprint, group: group, start_date: now + 1.day, due_date: now + 2.days) }

  context 'as guest' do
    before do
      visit group_iterations_path(group)
    end

    it 'hides New iteration button' do
      expect(page).not_to have_link('New iteration', href: new_group_iteration_path(group))
    end
  end

  context 'as user' do
    before do
      stub_licensed_features(iterations: true)
      group.add_owner(user)
      sign_in(user)
      visit group_iterations_path(group)
    end

    it 'shows "New iteration" button' do
      expect(page).to have_link('New iteration', href: new_group_iteration_path(group))
    end
  end
end
