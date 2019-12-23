# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::GroupTreeSaver do
  describe 'saves the group tree into a json object' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:label) { create(:group_label) }
    let_it_be(:parent_epic) { create(:epic, group: group) }
    let_it_be(:epic) { create(:epic, group: group, parent: parent_epic) }
    let_it_be(:board) { create(:board, group: group, assignee: user, labels: [label]) }
    let_it_be(:note) { create(:note, noteable: epic) }

    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec_ee" }
    let(:group_tree_saver) { described_class.new(group: group, current_user: user, shared: shared) }

    let(:saved_group_json) do
      group_json(group_tree_saver.full_path)
    end

    before do
      group.add_maintainer(user)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves successfully' do
      expect_successful_save(group_tree_saver)
    end

    context 'epics relation' do
      it 'saves top level epics' do
        expect_successful_save(group_tree_saver)
        expect(saved_group_json['epics'].size).to eq(2)
      end

      it 'saves parent of epic' do
        expect_successful_save(group_tree_saver)

        parent = saved_group_json['epics'].first['parent']

        expect(parent).not_to be_empty
        expect(parent['id']).to eq(parent_epic.id)
      end

      it 'saves epic notes' do
        expect_successful_save(group_tree_saver)

        notes = saved_group_json['epics'].first['notes']

        expect(notes).not_to be_empty
        expect(notes.first['note']).to eq(note.note)
        expect(notes.first['noteable_id']).to eq(epic.id)
      end
    end

    context 'boards relation' do
      it 'saves top level boards' do
        expect_successful_save(group_tree_saver)
        expect(saved_group_json['boards'].size).to eq(1)
      end

      it 'saves board assignee' do
        expect_successful_save(group_tree_saver)
        expect(saved_group_json['boards'].first['board_assignee']['assignee_id']).to eq(user.id)
      end

      it 'saves board labels' do
        expect_successful_save(group_tree_saver)

        labels = saved_group_json['boards'].first['labels']

        expect(labels).not_to be_empty
        expect(labels.first['title']).to eq(label.title)
      end
    end
  end

  def expect_successful_save(group_tree_saver)
    expect(group_tree_saver.save).to be true
    expect(group_tree_saver.shared.errors).to be_empty
  end

  def group_json(filename)
    JSON.parse(IO.read(filename))
  end
end
