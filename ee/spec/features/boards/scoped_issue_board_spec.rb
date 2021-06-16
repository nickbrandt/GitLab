# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Scoped issue boards', :js do
  include Spec::Support::Helpers::Features::TopNavSpecHelpers
  include FilteredSearchHelpers
  include MobileHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:project_2) { create(:project, :public, namespace: group) }
  let_it_be(:project_label) { create(:label, project: project, name: 'Planning') }
  let_it_be(:group_label) { create(:group_label, group: group, name: 'Group Label') }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:board) { create(:board, project: project, name: 'Project board') }
  let_it_be(:group_board) { create(:board, group: group, name: 'Group board') }
  let_it_be(:filtered_board) { create(:board, project: project_2, name: 'Filtered board', milestone: milestone, assignee: user, weight: 2) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:issue_milestone) { create(:closed_issue, project: project, milestone: milestone) }
  let_it_be(:assigned_issue) { create(:issue, project: project, assignees: [user]) }

  let(:edit_board) { find('.btn', text: 'Edit board') }
  let(:view_scope) { find('.btn', text: 'View scope') }
  let(:board_title) { find('.boards-selector-wrapper .dropdown-menu-toggle') }

  before_all do
    dismiss_top_nav_callout(user)
  end

  before do
    allow_next_instance_of(ApplicationHelper) do |helper|
      allow(helper).to receive(:collapsed_sidebar?).and_return(true)
    end

    stub_licensed_features(scoped_issue_board: true)
  end

  context 'user with edit permissions' do
    before do
      group.add_maintainer(user)

      login_as(user)

      # ensure there is enough vertical space for create/edit board modal
      resize_window(1920, 1080)
      visit project_boards_path(project)
      wait_for_requests
    end

    after do
      restore_window_size
    end

    context 'new board' do
      context 'milestone' do
        it 'creates board filtering by milestone' do
          create_board_milestone(milestone.title)

          expect(page).to have_css('.js-visual-token')
          expect(find('.tokens-container')).to have_content(:all, milestone.title)
          expect(page).to have_selector('.board-card', count: 1)
        end

        it 'creates board filtering by No milestone' do
          create_board_milestone('No milestone')

          expect(find('.tokens-container')).to have_content("")
          expect(page).to have_selector('.board-card', count: 2)
        end

        it 'creates board filtering by Any milestone' do
          create_board_milestone('Any milestone')

          expect(find('.tokens-container')).to have_content("")
          expect(page).to have_selector('.board-card', count: 3)
        end

        it 'displays dot highlight and tooltip' do
          create_board_milestone(milestone.title)

          expect_dot_highlight('Edit board')
        end
      end

      context 'labels' do
        let!(:label_1) { create(:label, project: project, name: 'Label 1') }
        let!(:label_2) { create(:label, project: project, name: 'Label 2') }
        let!(:issue) { create(:labeled_issue, project: project, labels: [label_1]) }
        let!(:issue_2) { create(:labeled_issue, project: project, labels: [label_2]) }
        let!(:issue_3) { create(:labeled_issue, project: project, labels: [label_1, label_2]) }

        it 'creates board filtering by one label' do
          create_board_label(label_1.title)

          expect(page).to have_css('.js-visual-token')
          expect(find('.tokens-container')).to have_content(:all, label_1.title)
          expect(page).to have_selector('.board-card', count: 2)
        end

        it 'creates board filtering by multiple labels' do
          create_board_label([label_1.title, label_2.title])

          expect(page).to have_css('.js-visual-token')
          expect(find('.tokens-container')).to have_content(:all, label_1.title)
          expect(find('.tokens-container')).to have_content(:all, label_2.title)
          expect(page).to have_selector('.board-card', count: 1)
        end

        it 'only shows group labels in list on group boards' do
          stub_licensed_features(multiple_group_issue_boards: true)

          visit group_boards_path(group)
          wait_for_requests

          expect(page).to have_css('.js-boards-selector')
          click_on_create_new_board

          click_button 'Expand'

          page.within('.labels') do
            click_button 'Edit'
            page.within('.labels-select-contents-list') do
              expect(page).to have_content(group_label.title)
              expect(page).not_to have_content(project_label.title)
            end
          end
        end

        it 'displays dot highlight and tooltip' do
          create_board_label(label_1.title)

          expect_dot_highlight('Edit board')
        end
      end

      context 'assignee' do
        it 'creates board filtering by assignee' do
          create_board_assignee(user.name)

          expect(page).to have_css('.js-visual-token')
          expect(find('.tokens-container')).to have_content(:all, user.name)
          expect(page).to have_selector('.board-card', count: 1)

          # Does not display assignee in search hint
          filtered_search.click

          page.within('#js-dropdown-hint') do
            expect(page).to have_content('Label')
            expect(page).not_to have_content('Assignee')
          end
        end

        it 'creates board filtering by "Any assignee"' do
          create_board_assignee('Any assignee')

          expect(page).not_to have_css('.js-visual-token')
          expect(page).to have_selector('.board-card', count: 3)
        end

        it 'displays dot highlight and tooltip' do
          create_board_assignee(user.name)

          expect_dot_highlight('Edit board')
        end
      end

      context 'weight' do
        let!(:issue_weight_1) { create(:issue, project: project, weight: 1) }
        let!(:issue_weight_0) { create(:issue, project: project, weight: 0) }
        let!(:issue_weight_none) { create(:issue, project: project, weight: nil) }

        it 'creates board filtering by weight' do
          create_board_weight(1)

          expect(page).to have_selector('.board-card', count: 1)
          expect(find('.board-card-title').text).to have_content(issue_weight_1.title)

          # Does not display assignee in search hint
          filtered_search.click

          page.within('#js-dropdown-hint') do
            expect(page).to have_content('Label')
            expect(page).not_to have_content('Weight')
          end
        end

        it 'creates board filtering by "Any" weight' do
          create_board_weight('Any')

          expect(page).to have_selector('.board-card', count: 6)
        end

        it 'creates board filtering by "None" weight' do
          create_board_weight('None')

          expect(page).to have_selector('.board-card', count: 4)
        end

        it 'creates board filtering by "0" weight' do
          create_board_weight(0)

          expect(page).to have_selector('.board-card', count: 1)
        end

        it 'displays dot highlight and tooltip' do
          create_board_weight(1)

          expect_dot_highlight('Edit board')
        end
      end
    end

    context 'edit board' do
      let!(:milestone_two) { create(:milestone, project: project) }

      it 'edits board name' do
        edit_board.click

        page.within('.modal') do
          fill_in 'board-new-name', with: 'Testing'

          click_button 'Save'
        end

        expect(board_title).to have_content('Testing')
        expect(board.reload.name).to eq('Testing')
      end

      it 'prefills fields' do
        visit project_boards_path(project_2)

        edit_board.click

        expect(find('.milestone .value')).to have_content(milestone.title)
        expect(find('.assignee .value')).to have_content(user.name)
        expect(find('.weight .value')).to have_content(2)
      end

      context 'milestone' do
        it 'sets board milestone' do
          update_board_milestone(milestone.title)

          expect(find('.tokens-container')).to have_content(:all, milestone.title)
          expect(page).to have_selector('.board-card', count: 1)
        end

        it 'sets board to any milestone' do
          update_board_milestone('Any milestone')

          expect(find('.tokens-container')).not_to have_content(milestone.title)

          find('.board-card', match: :first)

          expect(page).to have_selector('.board', count: 2)
          expect(all('.board').first).to have_selector('.board-card', count: 2)
          expect(all('.board').last).to have_selector('.board-card', count: 1)
        end

        it 'sets board to upcoming milestone' do
          update_board_milestone('Upcoming')

          expect(find('.tokens-container')).not_to have_content(milestone.title)

          find('.board', match: :first)

          expect(all('.board')[1]).to have_selector('.board-card', count: 0)
        end

        it 'does not display milestone in search hint' do
          update_board_milestone(milestone.title)
          filtered_search.click

          page.within('#js-dropdown-hint') do
            expect(page).to have_content('Label')
            expect(page).not_to have_content('Milestone')
          end
        end
      end

      context 'iteration' do
        context 'board not scoped to iteration' do
          it 'sets board to current iteration' do
            expect(page).to have_selector('.board-card', count: 3)

            update_board_scope('current_iteration', true)

            expect(page).to have_selector('.board-card', count: 0)
          end
        end

        context 'board scoped to current iteration' do
          it 'removes current iteration from board' do
            create_board_scope('current_iteration', true)

            expect(page).to have_selector('.board-card', count: 0)

            update_board_scope('current_iteration', false)

            expect(page).to have_selector('.board-card', count: 3)
          end
        end
      end

      context 'labels' do
        let!(:label_1) { create(:label, project: project, name: 'Label 1') }
        let!(:label_2) { create(:label, project: project, name: 'Label 2') }
        let!(:issue) { create(:labeled_issue, project: project, labels: [label_1]) }
        let!(:issue_2) { create(:labeled_issue, project: project, labels: [label_2]) }
        let!(:issue_3) { create(:labeled_issue, project: project, labels: [label_1, label_2]) }

        it 'adds label to board' do
          label_title = issue.labels.first.title
          visit project_boards_path(project)

          update_board_label(label_title)

          expect(page).to have_css('.js-visual-token')
          expect(find('.tokens-container')).to have_content(:all, label_title)

          expect(page).to have_selector('.board-card', count: 2)
        end

        it 'adds multiple labels to board' do
          label_title = issue.labels.first.title
          label_2_title = issue_2.labels.first.title

          visit project_boards_path(project)

          update_board_label(label_title)

          wait_for_all_requests

          update_board_label(label_2_title)

          expect(page).to have_css('.js-visual-token')
          expect(find('.tokens-container')).to have_content(:all, label_title)
          expect(find('.tokens-container')).to have_content(:all, label_2_title)

          expect(page).to have_selector('.board-card', count: 1)
        end

        it 'can filter by additional labels' do
          label_title = issue.labels.first.title
          label_2_title = issue_2.labels.first.title

          visit project_boards_path(project)

          update_board_label(label_title)

          input_filtered_search("label=~#{label_2_title}")

          expect(page).to have_selector('.board-card', count: 0)
        end

        context 'group board' do
          it 'only shows group labels in list' do
            stub_licensed_features(multiple_group_issue_boards: true)

            visit group_boards_path(group)
            edit_board.click

            page.within('.labels') do
              click_button 'Edit'
              page.within('.labels-select-contents-list') do
                expect(page).to have_content(group_label.title)
                expect(page).not_to have_content(project_label.title)
              end
            end
          end
        end
      end

      context 'assignee' do
        it 'sets board assignee' do
          update_board_assignee(user.name)

          expect(page).to have_css('.js-visual-token')
          expect(find('.tokens-container')).to have_content(:all, user.name)

          expect(page).to have_selector('.board-card', count: 1)
        end

        it 'sets board to Any assignee' do
          update_board_assignee('Any assignee')

          expect(page).not_to have_css('.js-visual-token')
          expect(page).to have_selector('.board-card', count: 3)
        end

        it 'does not display assignee in search hint' do
          update_board_assignee(user.name)
          filtered_search.click

          page.within('#js-dropdown-hint') do
            expect(page).to have_content('Label')
            expect(page).not_to have_content('Assignee')
          end
        end
      end

      context 'weight' do
        let!(:issue_weight_1) { create(:issue, project: project, weight: 1) }

        it 'sets board weight' do
          update_board_weight(1)

          expect(page).to have_selector('.board-card', count: 1)
          expect(find('.board-card-title').text).to have_content(issue_weight_1.title)
        end

        it 'sets board to Any weight' do
          update_board_weight('Any')

          expect(page).to have_selector('.board-card', count: 4)
        end

        it 'does not display weight in search hint' do
          update_board_weight(1)
          filtered_search.click

          page.within('#js-dropdown-hint') do
            expect(page).to have_content('Label')
            expect(page).not_to have_content('Weight')
          end
        end
      end
    end
  end

  context 'user without edit permissions' do
    before do
      visit project_boards_path(project)
      wait_for_requests
    end

    it 'can view board scope' do
      view_scope.click

      page.within('.modal') do
        expect(find('.modal-header')).to have_content('Board scope')
        expect(page).not_to have_content('Board name')
        expect(page).not_to have_link('Edit')
        expect(page).not_to have_button('Edit')
        expect(page).not_to have_button('Save')
        expect(page).not_to have_button('Cancel')
      end
    end

    it 'does not display dot highlight and tooltip' do
      expect_no_dot_highlight('View scope')
    end
  end

  context 'with scoped_issue_boards feature disabled' do
    before do
      stub_licensed_features(scoped_issue_board: false)

      project.add_maintainer(user)
      login_as(user)

      visit project_boards_path(project)
      wait_for_requests
    end

    it 'does not display dot highlight and tooltip' do
      expect_no_dot_highlight('Edit board')
    end

    it "doesn't show the input when creating a board" do
      click_on_create_new_board

      page.within '.js-board-config-modal' do
        # To make sure the form is shown
        expect(page).to have_field('board-new-name')

        expect(page).not_to have_button('Expand')
      end
    end

    it "doesn't show the button to edit scope" do
      expect(page).not_to have_button('View Scope')
    end
  end

  def expect_dot_highlight(button_title)
    button = first('.filter-dropdown-container .btn.gl-button.dot-highlight')
    expect(button.text).to include(button_title)
    expect(button['title']).to include('This board\'s scope is reduced')
  end

  def expect_no_dot_highlight(button_title)
    button = first('.filter-dropdown-container .btn.gl-button')
    expect(button.text).to include(button_title)
    expect(button[:class]).not_to include('dot-highlight')
    expect(button['title']).not_to include('This board\'s scope is reduced')
  end

  # Create board helper methods
  #
  def create_board_milestone(milestone_title)
    create_board_scope('milestone', milestone_title)
  end

  def create_board_label(label_title)
    create_board_scope('labels', label_title)
  end

  def create_board_weight(weight)
    create_board_scope('weight', weight.to_s)
  end

  def create_board_assignee(assignee_name)
    create_board_scope('assignee', assignee_name)
  end

  # Update board helper methods
  #
  def update_board_milestone(milestone_title)
    update_board_scope('milestone', milestone_title)
  end

  def update_board_label(label_title)
    update_board_scope('labels', label_title)
  end

  def update_board_assignee(assignee_name)
    update_board_scope('assignee', assignee_name)
  end

  def update_board_weight(weight)
    update_board_scope('weight', weight.to_s)
  end

  def create_board_scope(filter, value)
    click_on_create_new_board
    find('#board-new-name').set 'test'

    click_button 'Expand'

    click_value(filter, value)

    click_on_board_modal

    click_button 'Create board'

    wait_for_requests

    expect(page).not_to have_selector('.board-list-loading')
  end

  def click_value(filter, value)
    if filter == 'current_iteration'
      current_iteration_checkbox = 'Scope board to current iteration'
      if value
        check(current_iteration_checkbox)
      else
        uncheck(current_iteration_checkbox)
      end
    else
      page.within(".#{filter}") do
        click_button 'Edit'

        if value.is_a?(Array)
          value.each { |value| click_link value }
        elsif filter == 'weight'
          page.within(".dropdown-menu") do
            click_button value
          end
        else
          click_link value
        end
      end
    end
  end

  def click_on_create_new_board
    page.within '.js-boards-selector' do
      find('.dropdown-menu-toggle').click
      wait_for_requests

      click_button 'Create new board'
    end
  end

  def update_board_scope(filter, value)
    edit_board.click

    click_value(filter, value)

    click_on_board_modal

    click_button 'Save changes'

    wait_for_requests

    expect(page).not_to have_selector('.board-list-loading')
  end

  # Click on modal to make sure the dropdown is closed (e.g. label scenario)
  #
  def click_on_board_modal
    find('.board-config-modal .modal-content').click
  end
end
