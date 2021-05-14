# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User adds lists', :js do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:group_board) { create(:board, group: group) }
  let_it_be(:project_board) { create(:board, project: project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:milestone) { create(:milestone, project: project) }

  let_it_be(:group_label) { create(:group_label, group: group) }
  let_it_be(:project_label) { create(:label, project: project) }
  let_it_be(:group_backlog_list) { create(:backlog_list, board: group_board) }
  let_it_be(:project_backlog_list) { create(:backlog_list, board: project_board) }

  let_it_be(:issue) { create(:labeled_issue, project: project, labels: [group_label, project_label]) }

  before_all do
    project.add_maintainer(user)
    group.add_owner(user)
  end

  where(:board_type, :graphql_board_lists_enabled) do
    :project | true
    :project | false
    :group   | true
    :group   | false
  end

  with_them do
    before do
      sign_in(user)

      set_cookie('sidebar_collapsed', 'true')

      stub_feature_flags(
        graphql_board_lists: graphql_board_lists_enabled,
      )

      if board_type == :project
        visit project_board_path(project, project_board)
      elsif board_type == :group
        visit group_board_path(group, group_board)
      end

      wait_for_all_requests
    end

    it 'creates new column for label containing labeled issue' do
      click_button 'Create list'
      wait_for_all_requests

      select_label(group_label)

      wait_for_all_requests

      expect(page).to have_selector('.board', text: group_label.title)
      expect(find('.board:nth-child(2) .board-card')).to have_content(issue.title)
    end
  end

  def select_label(label)
    click_button 'Select a label'

    find('label', text: label.title).click

    click_button 'Add to board'

    wait_for_all_requests
  end
end
