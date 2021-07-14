# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown hint', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_hint) { '#js-dropdown-hint' }
  let(:js_dropdown_operator) { '#js-dropdown-operator' }

  def click_hint(text)
    find('#js-dropdown-hint .filter-dropdown .filter-dropdown-item', text: text).click
  end

  def click_operator(op)
    find("#js-dropdown-operator .filter-dropdown .filter-dropdown-item[data-value='#{op}']").click
  end

  before do
    project.add_maintainer(user)
  end

  context 'when user not logged in' do
    before do
      visit project_issues_path(project)
    end

    it 'does not exist my-reaction dropdown item' do
      click_empty_filtered_search_bar

      expect(page).not_to have_link('My-reaction')
    end
  end

  context 'when user logged in' do
    before do
      sign_in(user)

      visit project_issues_path(project)
    end

    describe 'behavior' do
      before do
        click_empty_filtered_search_bar
      end

      it 'opens when the search bar is first focused' do
        expect_visible_suggestions_list

        find('body').click

        expect_hidden_suggestions_list
      end
    end

    describe 'filtering' do
      it 'filters with text' do
        click_empty_filtered_search_bar
        send_keys 'la'

        expect_filtered_search_suggestion_count(1)
      end
    end

    describe 'selecting from dropdown with no input' do
      before do
        click_empty_filtered_search_bar
      end

      it 'opens the token dropdown when you click on it' do
        click_link 'Assignee'

        expect_visible_suggestions_list
        expect_suggestion('=')

        click_link '= is'

        expect_visible_suggestions_list
        expect_token_segment('Assignee')
        expect_token_segment('=')
        expect_empty_search_term
      end
    end

    describe 'reselecting from dropdown' do
      it 'reuses existing token text' do
        click_empty_filtered_search_bar
        send_keys('author', :backspace, :backspace)

        click_link('Author')

        expect_token_segment('Author')
        expect_empty_search_term
      end
    end
  end
end
