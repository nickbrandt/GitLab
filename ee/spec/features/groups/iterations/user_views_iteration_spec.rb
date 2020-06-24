# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views iteration' do
  let_it_be(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }
  let_it_be(:iteration) { create(:iteration, :skip_future_date_validation, group: group, start_date: now - 1.day, due_date: now) }

  around do |example|
    Timecop.freeze { example.run }
  end

  before do
    sign_in(user)
  end

  context 'view an iteration', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/222915' do
    before do
      visit group_iteration_path(iteration.group, iteration)
    end

    it 'shows iteration info and dates' do
      expect(page).to have_content(iteration.title)
      expect(page).to have_content(iteration.description)
    end
  end
end
