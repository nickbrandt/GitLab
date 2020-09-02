# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics swimlanes', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:label) { create(:label, project: project, name: 'Label 1') }
  let_it_be(:list) { create(:list, board: board, label: label, position: 0) }

  let_it_be(:issue1) { create(:issue, project: project, labels: [label]) }
  let_it_be(:issue2) { create(:issue, project: project) }
  let_it_be(:issue3) { create(:issue, project: project) }

  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }

  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic2, issue: issue2) }

  context 'switch to swimlanes view' do
    context 'feature flag on' do
      before do
        stub_licensed_features(epics: true)
        sign_in(user)
        visit_board_page

        page.within('.board-swimlanes-toggle-wrapper') do
          page.find('.dropdown-toggle').click
          page.find('.dropdown-item', text: 'Epic').click
        end
      end

      it 'displays epics swimlanes when selecting Epic in Group by dropdown' do
        expect(page).to have_css('.board-swimlanes')

        epic_lanes = page.all(:css, '.board-epic-lane')
        expect(epic_lanes.length).to eq(2)
      end

      it 'displays issue not assigned to epic in unassigned issues lane' do
        page.within('.board-lane-unassigned-issues') do
          expect(page.find('span[data-testid="issues-lane-issue-count"]')).to have_content('1')
        end
      end
    end
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_requests
  end
end
