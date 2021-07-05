# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Visual tokens', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:user_rock) { create(:user, name: 'The Rock', username: 'rock') }
  let_it_be(:milestone_nine) { create(:milestone, title: '9.0', project: project) }
  let_it_be(:milestone_ten) { create(:milestone, title: '10.0', project: project) }
  let_it_be(:label) { create(:label, project: project, title: 'abc') }
  let_it_be(:cc_label) { create(:label, project: project, title: 'Community Contribution') }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_user(user, :maintainer)
    project.add_user(user_rock, :maintainer)
    sign_in(user)

    set_cookie('sidebar_collapsed', 'true')

    visit project_issues_path(project)
  end

  describe 'editing a single token' do
    before do
      select_tokens 'Author', user.username, 'Assignee', '=', 'None', submit: false
      click_token_segment(user.username)
      wait_for_requests
    end

    it 'opens author dropdown' do
      expect_visible_suggestions_list
      expect(page).to have_field('Search', with: 'root')
    end

    it 'filters value' do
      send_keys :backspace

      expect_filtered_search_suggestion_count(1)
    end

    it 'ends editing mode when document is clicked' do
      find('.js-navbar').click

      expect_empty_search_term
      expect_hidden_suggestions_list
    end

    describe 'selecting different author from dropdown' do
      before do
        send_keys :backspace, :backspace, :backspace, :backspace
        click_on user_rock.name
      end

      it 'changes value in visual token' do
        wait_for_requests
        expect(first('.gl-filtered-search-token-segment:nth-child(3)').text).to eq(user_rock.name)
      end
    end
  end

  describe 'editing multiple tokens' do
    before do
      select_tokens 'Author', user.username, 'Assignee', '=', 'None', submit: false
      click_token_segment(user.username)
    end

    it 'opens author dropdown' do
      expect_visible_suggestions_list
    end

    it 'opens assignee dropdown' do
      click_token_segment('Assignee')
      expect_visible_suggestions_list
    end
  end

  describe 'editing a search term while editing another filter token' do
    before do
      click_empty_filtered_search_bar
      send_keys 'foo '
      click_on 'Assignee'
      click_on '= is'

      click_token_segment('foo')
      send_keys ' '
    end

    it 'opens author dropdown' do
      click_on 'Label'

      expect_visible_suggestions_list

      click_on '= is'

      expect_visible_suggestions_list
    end
  end

  describe 'add new token after editing existing token' do
    before do
      select_tokens 'Author', user.username, 'Assignee', '=', 'None', submit: false
      click_token_segment(user.username)
      send_keys(' ')
    end

    describe 'opens dropdowns' do
      it 'opens hint dropdown' do
        expect_visible_suggestions_list
      end

      it 'opens token dropdown' do
        click_on 'Assignee'
        click_on '= is'

        expect_visible_suggestions_list
      end
    end

    describe 'visual tokens' do
      it 'creates visual token' do
        click_on 'Assignee'
        click_on '= is'
        click_on 'The Rock'

        expect_assignee_token('The Rock')
      end
    end

    it 'does not tokenize incomplete token' do
      click_on 'Assignee'
      click_on '= is'

      find('.js-navbar').click

      expect_empty_search_term
      expect_token_segment('Assignee')
    end
  end

  describe 'search using incomplete visual tokens' do
    before do
      select_tokens 'Author', user.username, 'Assignee', '=', 'None', submit: false
    end

    it 'tokenizes the search term to complete visual token' do
      expect_author_token(user.name)
      expect_assignee_token('None')
    end
  end

  it 'does retain hint token when mix of typing and clicks are performed' do
    select_tokens 'Label', submit: false

    click_on '= is'

    expect_token_segment('Label')
    expect_token_segment('=')
  end

  describe 'Any/None option' do
    it 'hidden when NOT operator is selected' do
      select_tokens 'Milestone', '!=', submit: false

      expect_no_suggestion('Any')
      expect_no_suggestion('None')
    end

    it 'shown when EQUAL operator is selected' do
      select_tokens 'Milestone', '=', submit: false

      expect_suggestion('Any')
      expect_suggestion('None')
    end
  end
end
