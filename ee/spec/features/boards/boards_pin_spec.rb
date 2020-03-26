# frozen_string_literal: true

require 'spec_helper'

describe 'issue boards', :js do
  include DragTo

  let(:group) { create(:group, name: 'test_group') }
  let(:owner) { create(:group_member, :owner, group: group, user: create(:user, name: 'shodan' )).user }
  let(:project) { create(:project, :public, name: 'test_project', namespace: group) }
  let(:board) { create(:board, project: project) }
  let(:planning) { create(:label, project: project, name: 'Planning') }
  let(:label) { create(:label, project: project) }
  let(:milestone) { create(:milestone, project: project) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
  end

  shared_examples 'run pins' do |type|
    let!(:list1) { create(:list, board: board, label: planning, position: 0) }
    let!(:list2) { create(:list, board: board, label: label, position: 1) }
    let!(:list3) { create(:milestone_list, board: board, milestone: milestone, position: 2) }
    let!(:list4) { create(:user_list, board: board, user: owner, position: 3) }
    let!(:issue) { create(:labeled_issue, project: project, title: 'abc', description: 'def', labels: [planning]) }
    let!(:issue2) { create(:labeled_issue, project: project, title: 'hij', description: 'klm', labels: [label]) }
    let!(:issue3) { create(:issue, project: project, title: 'nop', description: 'qrs', milestone: milestone) }

    pin_type = ENV['PIN_TYPE'] || 'pin'
    type = "#{type}.#{pin_type}"

    it 'as_guest' do
      project.add_guest(user)
      login_as(user)

      visit_board_page

      save_pin('as_guest', type)
    end

    it 'as_developer' do
      project.add_developer(user)
      login_as(user)

      visit_board_page

      save_pin('as_developer', type)
    end

    it 'as_maintainer' do
      project.add_maintainer(user)
      login_as(user)

      visit_board_page

      save_pin('as_maintainer', type)
    end
  end

  context "ff off" do
    before do
      stub_feature_flags(sfc_issue_boards: false)
    end

    it_behaves_like 'run pins', 'ff_off'
  end

  context "ff on" do
    before do
      stub_feature_flags(sfc_issue_boards: true)
    end

    it_behaves_like 'run pins', 'ff_on'
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_requests
  end

  def save_pin(name, type)
    path = File.dirname(__FILE__) + "/pins/#{name}.#{type}.html"

    html = page.find('.boards-app')['outerHTML']

    File.write(path, html, mode: 'wb')
  end
end
