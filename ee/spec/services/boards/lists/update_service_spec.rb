# frozen_string_literal: true

require 'spec_helper'

describe 'EE::Boards::Lists::UpdateService' do
  let(:group) { create(:group) }
  let(:user) { create(:group_member, :owner, group: group, user: create(:user)).user }
  let(:unpriviledged_user) { create(:group_member, :guest, group: group, user: create(:user)).user }

  shared_examples 'board list update' do
    context 'with licensed wip limits' do
      before do
        stub_licensed_features(wip_limits: true)
      end

      it 'updates the list if max_issue_count is given' do
        service = Boards::Lists::UpdateService.new(board, user, max_issue_count: 42)
        expect(service.execute(list)).to be_truthy

        reloaded_list = list.reload
        expect(reloaded_list.max_issue_count).to eq(42)
      end

      it 'updates the list with max_issue_count of 0 if max_issue_count is nil' do
        service = Boards::Lists::UpdateService.new(board, user, max_issue_count: nil)
        expect(service.execute(list)).to be_truthy

        reloaded_list = list.reload
        expect(reloaded_list.max_issue_count).to eq(0)
      end

      it 'does not update the list if can_admin returns false' do
        service = Boards::Lists::UpdateService.new(board, unpriviledged_user, max_issue_count: 42)
        expect(service.execute(list)).to be_truthy

        reloaded_list = list.reload
        expect(reloaded_list.max_issue_count).to eq(0)
      end
    end

    context 'without licensed wip limits' do
      before do
        stub_licensed_features(wip_limits: false)
      end

      it 'does not update the list even if max_issue_count is given' do
        service = Boards::Lists::UpdateService.new(board, user, max_issue_count: 42)
        expect(service.execute(list)).to be_truthy

        reloaded_list = list.reload
        expect(reloaded_list.max_issue_count).to eq(0)
      end

      it 'does not update the list if can_admin returns false' do
        service = Boards::Lists::UpdateService.new(board, unpriviledged_user, max_issue_count: 42)
        expect(service.execute(list)).to be_truthy

        reloaded_list = list.reload
        expect(reloaded_list.max_issue_count).to eq(0)
      end
    end
  end

  context 'with project' do
    let(:project_board) { create(:board, project: project) }
    let(:project) { create(:project, group: group) }
    let(:project_board_list) { create(:list, board: project_board) }
    let(:board) { project_board }
    let(:list) { project_board_list }

    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'board list update'
  end

  context 'with group' do
    let(:group) { create(:group) }
    let(:group_board) { create(:board, group: group) }
    let(:group_board_list) { create(:list, board: group_board) }
    let(:board) { group_board }
    let(:list) { group_board_list }

    before do
      group.add_owner(user)
    end

    it_behaves_like 'board list update'
  end
end
