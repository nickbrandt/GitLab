# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::GroupTreeRestorer do
  include ImportExport::CommonUtil

  let(:user) { create(:user) }
  let(:group) { create(:group, name: 'group', path: 'group') }
  let(:shared) { Gitlab::ImportExport::Shared.new(group) }
  let(:group_tree_restorer) { described_class.new(user: user, shared: shared, group: group, group_hash: nil) }

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)

    setup_import_export_config('group_exports/light', 'ee')
    group.add_owner(user)
    group_tree_restorer.restore
  end

  describe 'restore group tree' do
    context 'epics' do
      it 'has group epics' do
        expect(group.epics.count).to eq(1)
      end

      it 'has award emoji' do
        expect(group.epics.first.award_emoji.first.name).to eq('thumbsup')
      end
    end

    context 'epic notes' do
      it 'has epic notes' do
        expect(group.epics.first.notes.count).to eq(1)
      end

      it 'has award emoji on epic notes' do
        expect(group.epics.first.notes.first.award_emoji.first.name).to eq('drum')
      end
    end

    context 'board lists' do
      it 'has milestone & assignee lists' do
        lists = group.boards.find_by(name: 'first board').lists

        expect(lists.map(&:list_type)).to contain_exactly('assignee', 'milestone')
      end
    end
  end
end
