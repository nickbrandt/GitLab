# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recent searches', :js do
  include FilteredSearchHelpers
  include MobileHelpers

  let_it_be(:project_1) { create(:project, :public) }
  let_it_be(:project_2) { create(:project, :public) }
  let_it_be(:issue_1) { create(:issue, project: project_1) }
  let_it_be(:issue_2) { create(:issue, project: project_2) }

  let(:project_1_local_storage_key) { "#{project_1.full_path}-issue-recent-searches" }

  before do
    Capybara.ignore_hidden_elements = false

    # Visit any fast-loading page so we can clear local storage without a DOM exception
    visit '/404'
    remove_recent_searches
  end

  after do
    Capybara.ignore_hidden_elements = true
  end

  def submit_search(search)
    click_empty_filtered_search_bar
    send_keys(search, :enter)
    click_button 'Clear'
  end

  it 'searching adds to recent searches' do
    visit project_issues_path(project_1)

    submit_search 'search1'
    submit_search 'search2'

    click_button 'Toggle history'

    items = all('.gl-search-box-by-click-history-item', count: 2)

    expect(items[0].text).to eq('search2')
    expect(items[1].text).to eq('search1')
  end

  it 'visiting URL with search params adds to recent searches' do
    visit project_issues_path(project_1, label_name: 'foo', search: 'bar')
    visit project_issues_path(project_1, label_name: 'qux', search: 'garply')

    click_button 'Toggle history'

    items = all('.gl-search-box-by-click-history-item', count: 2)

    expect(items[0].text).to eq('Label := qux garply')
    expect(items[1].text).to eq('Label := foo bar')
  end

  it 'saved recent searches are restored last on the list' do
    set_recent_searches(project_1_local_storage_key, '[[{"type":"filtered-search-term","value":{"data":"saved1"}}],[{"type":"filtered-search-term","value":{"data":"saved2"}}]]')

    visit project_issues_path(project_1, search: 'foo')

    click_button 'Toggle history'

    items = all('.gl-search-box-by-click-history-item', count: 3)

    expect(items[0].text).to eq('foo')
    expect(items[1].text).to eq('saved1')
    expect(items[2].text).to eq('saved2')
  end

  it 'searches are scoped to projects' do
    visit project_issues_path(project_1)

    submit_search 'foo'
    submit_search 'bar'

    visit project_issues_path(project_2)

    submit_search 'more'
    submit_search 'things'

    click_button 'Toggle history'

    items = all('.gl-search-box-by-click-history-item', count: 2)

    expect(items[0].text).to eq('things')
    expect(items[1].text).to eq('more')
  end

  it 'clicking item fills search input' do
    set_recent_searches(project_1_local_storage_key, '[[{"type":"filtered-search-term","value":{"data":"foo"}}],[{"type":"filtered-search-term","value":{"data":"bar"}}]]')
    visit project_issues_path(project_1)

    click_button 'Toggle history'
    click_button 'foo'

    expect_search_term('foo')
  end

  it 'clear recent searches button, clears recent searches' do
    set_recent_searches(project_1_local_storage_key, '[[{"type":"filtered-search-term","value":{"data":"foo"}}]]')
    visit project_issues_path(project_1)

    click_button 'Toggle history'

    expect(page).to have_css '.gl-search-box-by-click-history-item', count: 1

    click_button 'Clear recent searches'
    click_button 'Toggle history'

    expect(page).to have_text "You don't have any recent searches"
    expect(page).not_to have_css '.gl-search-box-by-click-history-item'
  end

  it 'shows flash error when failed to parse saved history' do
    set_recent_searches(project_1_local_storage_key, 'fail')
    visit project_issues_path(project_1)

    expect(find('.flash-alert')).to have_text('An error occurred while parsing recent searches')
  end
end
