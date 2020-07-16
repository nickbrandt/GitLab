# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views iteration' do
  let_it_be(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }
  let_it_be(:iteration) { create(:iteration, :skip_future_date_validation, iid: 1, id: 2, group: group, title: 'Correct Iteration', start_date: now - 1.day, due_date: now) }
  let_it_be(:other_iteration) { create(:iteration, :skip_future_date_validation, iid: 2, id: 1, group: group, title: 'Wrong Iteration', start_date: now - 4.days, due_date: now - 3.days) }
  let_it_be(:issue) { create(:issue, project: project, iteration: iteration) }
  let_it_be(:assigned_issue) { create(:issue, project: project, iteration: iteration, assignees: [user]) }
  let_it_be(:closed_issue) { create(:closed_issue, project: project, iteration: iteration) }
  let_it_be(:other_issue) { create(:issue, project: project, iteration: other_iteration) }

  context 'with license' do
    before do
      stub_licensed_features(iterations: true)
      sign_in(user)
    end

    context 'view an iteration', :js do
      before do
        visit group_iteration_path(iteration.group, iteration)
      end

      it 'shows iteration info and dates' do
        expect(page).to have_content(iteration.title)
        expect(page).to have_content(iteration.description)
        expect(page).to have_content(iteration.start_date.strftime('%b %-d, %Y'))
        expect(page).to have_content(iteration.due_date.strftime('%b %-d, %Y'))
      end

      it 'shows correct issues for issue' do
        expect(page).to have_content(issue.title)
        expect(page).to have_content(assigned_issue.title)
        expect(page).to have_content(closed_issue.title)
        expect(page).not_to have_content(other_issue.title)
      end
    end
  end
end
