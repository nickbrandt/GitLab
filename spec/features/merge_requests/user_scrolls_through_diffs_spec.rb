# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User scrolls through diffs', :js do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:project) { create(:project, :public, :repository) }

  before do
    visit(diffs_project_merge_request_path(project, merge_request))
  end

  it 'shows merge title' do
    expect(page).to have_selector('.title', visible: true)
  end

  it 'allows the file tree to highight diff currently present in view port' do
    find('.js-toggle-tree-list').click

    diffs = find_all('.diff-file')
    scroll_to(diffs[3])

    expect(find('.tree-list-scroll')).to have_css('.is-active')
  end
end
