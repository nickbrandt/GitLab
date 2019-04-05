require 'rails_helper'

describe 'Issue Boards add issue modal', :js do
  let(:project) { create(:project, :public) }
  let(:board) { create(:board, project: project) }
  let(:user) { create(:user) }
  let!(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:label) { create(:label, project: project) }
  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let!(:list2) { create(:list, board: board, label: label, position: 1) }
  let!(:issue) { create(:issue, project: project, title: 'abc', description: 'def') }
  let!(:issue2) { create(:issue, project: project, title: 'hij', description: 'klm') }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  it 'shows weight filter' do
    click_button('Add issues')
    wait_for_requests
    find('.add-issues-search .filtered-search').click

    expect(page.find('.filter-dropdown')).to have_content 'weight'
  end
end