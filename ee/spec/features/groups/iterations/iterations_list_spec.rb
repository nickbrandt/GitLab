# frozen_string_literal: true

require 'spec_helper'

describe 'Iterations list', :js do  
  let(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let!(:started_group_sprint) { create(:sprint, :skip_future_date_validation, group: group, title: 'one test', start_date: now - 1.day, due_date: now) }
  let!(:upcoming_group_sprint) { create(:sprint, group: group, start_date: now + 1.day, due_date: now + 2.days) }

  before do
    visit group_iterations_path(group)
  end

  it 'shows "New iteration" button' do
    # todo: check href as well
    expect(page).to have_link('New iteration')
  end
end
