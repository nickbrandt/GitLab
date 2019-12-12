# frozen_string_literal: true


require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
describe Gitlab::BackgroundMigration::UserMentions::CreateResourceUserMention do
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

  context 'migrate issue mentions' do
    let(:project) { create(:project, :private, namespace: group) }
    let(:issue) { create(:issue, project: project, author: author, description: description_mentions) }
    let!(:issue_without_mentions) { create(:issue, project: project, author: author, description: 'some description') }

    it 'migrates mentions' do
      join = 'LEFT JOIN issue_user_mentions on issues.id = issue_user_mentions.issue_id'
      conditions = "(description like '%@%' OR title like '%@%') AND issue_user_mentions.issue_id is null"

      expect do
        subject.perform('Issue', join, conditions, false, issue.id, issue.id)
      end.to change { IssueUserMention.count }.by(1)

      issue_user_mention = IssueUserMention.last
      expect(issue_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
      expect(issue_user_mention.mentioned_groups_ids.sort).to eq([group.id])
      expect(issue_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
    end

    context 'mentions in note' do
      let(:issue_note) { create(:note, noteable: issue, project: project, author: author, note: description_mentions) }
      let!(:issue_note2) { create(:note, noteable: issue, project: project, author: author, note: 'sample note') }

      it 'migrates mentions from note' do
        conditions = "note LIKE '%@%' AND issue_user_mentions.issue_id IS NULL AND notes.noteable_type = 'Issue' AND notes.system = false"
        join = 'INNER JOIN issues ON issues.id = notes.noteable_id LEFT JOIN issue_user_mentions ON notes.id = issue_user_mentions.note_id'

        expect do
          subject.perform('Issue', join, conditions, true, issue_note.id, issue_note.id)
        end.to change { IssueUserMention.where(note_id: issue_note.id).count }.by(1)

        epic_user_mention = IssueUserMention.last
        expect(epic_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
        expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
        expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
      end
    end
  end

  context 'migrate merge request mentions' do
    let(:project) { create(:project, :private, namespace: group) }
    let(:merge_request) { create(:merge_request, author: author, source_project: project, title: 'Test', description: description_mentions) }
    let(:merge_request2) { create(:merge_request, author: author, source_project: project, title: 'Test') }

    it 'migrates mentions' do
      join = 'LEFT JOIN merge_request_user_mentions on merge_requests.id = merge_request_user_mentions.merge_request_id'
      conditions = "(description like '%@%' OR title like '%@%') AND merge_request_user_mentions.merge_request_id is null"

      expect do
        subject.perform('MergeRequest', join, conditions, false, merge_request.id, merge_request.id)
      end.to change { MergeRequestUserMention.count }.by(1)

      merge_request_user_mention = MergeRequestUserMention.last
      expect(merge_request_user_mention.mentioned_users_ids&.sort).to eq(users.pluck(:id).sort)
      expect(merge_request_user_mention.mentioned_groups_ids&.sort).to eq([group.id])
      expect(merge_request_user_mention.mentioned_groups_ids&.sort).not_to include(inaccessible_group.id)
    end

    context 'mentions in note' do
      let(:merge_request_note) { create(:note, noteable: merge_request, project: project, author: author, note: description_mentions) }
      let!(:merge_request_note2) { create(:note, noteable: merge_request, project: project, author: author, note: 'sample note') }

      it 'migrates mentions from note' do
        conditions = "note LIKE '%@%' AND merge_request_user_mentions.merge_request_id IS NULL AND notes.noteable_type = 'MergeRequest' AND notes.system = false"
        join = 'INNER JOIN merge_requests ON merge_requests.id = notes.noteable_id LEFT JOIN merge_request_user_mentions ON notes.id = merge_request_user_mentions.note_id'

        expect do
          subject.perform('MergeRequest', join, conditions, true, merge_request_note.id, merge_request_note.id)
        end.to change { MergeRequestUserMention.where(note_id: merge_request_note.id).count }.by(1)

        epic_user_mention = MergeRequestUserMention.last
        expect(epic_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
        expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
        expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
      end
    end
  end

  context 'migrate snippet mentions' do
    let(:project) { create(:project, :private, namespace: group) }
    let(:snippet) { create(:snippet, project: project, author: author, description: description_mentions) }
    let(:snippet_without_mentions) { create(:snippet, project: project, author: author, description: 'some description') }

    it 'migrates mentions' do
      join = 'LEFT JOIN snippet_user_mentions on snippets.id = snippet_user_mentions.snippet_id'
      conditions = "(description like '%@%' OR title like '%@%') AND snippet_user_mentions.snippet_id is null"

      expect do
        subject.perform('Snippet', join, conditions, false, snippet.id, snippet.id)
      end.to change { SnippetUserMention.count }.by(1)

      snippet_user_mention = SnippetUserMention.last
      expect(snippet_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
      expect(snippet_user_mention.mentioned_groups_ids.sort).to eq([group.id])
      expect(snippet_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
    end

    context 'mentions in note' do
      let(:snippet_note) { create(:note, noteable: snippet, project: project, author: author, note: description_mentions) }
      let!(:snippet_note2) { create(:note, noteable: snippet, project: project, author: author, note: 'sample note') }

      it 'migrates mentions from note' do
        conditions = "note LIKE '%@%' AND snippet_user_mentions.snippet_id IS NULL AND notes.noteable_type = 'Snippet' AND notes.system = false"
        join = 'INNER JOIN snippets ON snippets.id = notes.noteable_id LEFT JOIN snippet_user_mentions ON notes.id = snippet_user_mentions.note_id'

        expect do
          subject.perform('Snippet', join, conditions, true, snippet_note.id, snippet_note.id)
        end.to change { SnippetUserMention.where(note_id: snippet_note.id).count }.by(1)

        epic_user_mention = SnippetUserMention.last
        expect(epic_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
        expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
        expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
      end
    end
  end

  context 'migrate commit mentions' do
    let(:project) { create(:project, :private, namespace: group) }
    let(:commit_note) { create(:note_on_commit, project: project, author: author, note: description_mentions) }
    let!(:commit_note2) { create(:note_on_commit, project: project, author: author, note: 'sample note') }

    it 'migrates mentions from note' do
      join = 'LEFT JOIN commit_user_mentions ON notes.id = commit_user_mentions.note_id'
      conditions = "note LIKE '%@%' AND commit_user_mentions.commit_id IS NULL AND notes.noteable_type = 'Commit' AND notes.system = false"

      expect do
        subject.perform('Commit', join, conditions, true, commit_note.id, commit_note.id)
      end.to change { CommitUserMention.count }.by(1)

      commit_user_mention = CommitUserMention.last
      expect(commit_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
      expect(commit_user_mention.mentioned_groups_ids.sort).to eq([group.id])
      expect(commit_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
