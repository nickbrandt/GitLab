# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
describe Gitlab::BackgroundMigration::CreateResourceUserMention do
  let(:author) { create(:user, username: 'author') }
  let(:non_member) { create(:user, username: 'non_member') }
  let(:member) { create(:user, username: 'member') }
  let(:guest) { create(:user, username: 'guest') }
  let(:admin) { create(:admin, username: 'administrator') }
  let(:john_doe) { create(:user, username: 'john_doe') }
  let(:skipped) { create(:user, username: 'skipped') }

  let(:users) { [author, non_member, member, guest, admin, john_doe, skipped] }
  let(:user_mentions) { users.map(&:to_reference).join(' ') }

  let(:group) { create(:group) }
  let(:inaccessible_group) { create(:group, :private) }
  let(:group_mentions) { [group, inaccessible_group].map { |gr| gr.to_reference(full: true) } }

  let(:description_mentions) { "description with mentions #{user_mentions} and #{group_mentions}" }

  context 'migrate epic mentions' do
    let(:epic) { create(:epic, group: group, author: author, description: description_mentions) }

    it 'migrates mentions' do
      join = 'LEFT JOIN epic_user_mentions on epics.id = epic_user_mentions.epic_id'
      conditions = "(description like '%@%' OR title like '%@%') AND epic_user_mentions.epic_id is null"

      expect do
        subject.perform('Epic', join, conditions, false, epic.id, epic.id)
      end.to change { EpicUserMention.count }.by(1)

      epic_user_mention = EpicUserMention.last
      expect(epic_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
      expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
      expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
    end

    context 'mentions in note' do
      let(:epic_note) { create(:note, noteable: epic, author: author, note: description_mentions) }
      let(:epic_note2) { create(:note, noteable: epic, author: author, note: 'sample note') }

      it 'migrates mentions from note' do
        conditions = "note LIKE '%@%' AND epic_user_mentions.epic_id IS NULL AND notes.noteable_type = 'Epic' AND notes.system = false"
        join = 'INNER JOIN epics ON epics.id = notes.noteable_id LEFT JOIN epic_user_mentions ON notes.id = epic_user_mentions.note_id'

        expect do
          subject.perform('Epic', join, conditions, true, epic_note.id, epic_note.id)
        end.to change { EpicUserMention.where(note_id: epic_note.id).count }.by(1)

        epic_user_mention = EpicUserMention.last
        expect(epic_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
        expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
        expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
      end
    end
  end

  context 'migrate design mentions' do
    let(:project) { create(:project, :private, namespace: group) }
    let(:design) { create(:design, :with_file, project: project) }
    let(:design_note) { create(:note, :on_design, noteable: design, project: project, author: author, note: description_mentions) }
    let!(:design_note2) { create(:note, :on_design, noteable: design, project: project, author: author, note: 'sample note') }

    it 'migrates mentions' do
      join = 'INNER JOIN design_management_designs ON notes.noteable_id = design_management_designs.id LEFT JOIN design_user_mentions ON notes.id = design_user_mentions.note_id'
      conditions = "note LIKE '%@%' AND notes.noteable_type = 'DesignManagement::Design' AND notes.system = false AND design_user_mentions.design_id IS NULL"

      expect do
        subject.perform('DesignManagement::Design', join, conditions, true, design_note.id, design_note.id)
      end.to change { DesignUserMention.count }.by(1)

      design_user_mention = DesignUserMention.last
      expect(design_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
      expect(design_user_mention.mentioned_groups_ids.sort).to eq([group.id])
      expect(design_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
