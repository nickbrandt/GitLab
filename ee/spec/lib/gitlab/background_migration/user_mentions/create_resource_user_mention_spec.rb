# frozen_string_literal: true

require 'spec_helper'
require './db/post_migrate/20191115115043_migrate_epic_mentions_to_db'
require './db/post_migrate/20191115115522_migrate_epic_notes_mentions_to_db'

describe Gitlab::BackgroundMigration::UserMentions::CreateResourceUserMention do
  include MigrationsHelpers

  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }
  let(:notes) { table(:notes) }
  let(:epic_user_mentions) { table(:epic_user_mentions) }

  let(:author) { users.create!(email: 'author@example.com', notification_email: 'author@example.com', name: 'author', username: 'author', projects_limit: 10, state: 'active') }
  let(:member) { users.create!(email: 'member@example.com', notification_email: 'member@example.com', name: 'member', username: 'member', projects_limit: 10, state: 'active') }
  let(:admin) { users.create!(email: 'administrator@example.com', notification_email: 'administrator@example.com', name: 'administrator', username: 'administrator', admin: 1, projects_limit: 10, state: 'active') }
  let(:john_doe) { users.create!(email: 'john_doe@example.com', notification_email: 'john_doe@example.com', name: 'john_doe', username: 'john_doe', projects_limit: 10, state: 'active') }
  let(:skipped) { users.create!(email: 'skipped@example.com', notification_email: 'skipped@example.com', name: 'skipped', username: 'skipped', projects_limit: 10, state: 'active') }

  let(:mentioned_users) { [author, member, admin, john_doe, skipped] }
  let(:user_mentions) { mentioned_users.map { |u| "@#{u.username}" }.join(' ') }

  let(:group) { namespaces.create!(name: 'test1', path: 'test1', runners_token: 'my-token1', project_creation_level: 1, visibility_level: 20, type: 'Group') }
  let(:inaccessible_group) { namespaces.create!(name: 'test2', path: 'test2', runners_token: 'my-token2', project_creation_level: 1, visibility_level: 0, type: 'Group') }

  let(:mentioned_groups) { [group, inaccessible_group] }
  let(:group_mentions) { [group, inaccessible_group].map { |gr| "@#{gr.path}" }.join(' ') }
  let(:description_mentions) { "description with mentions #{user_mentions} and #{group_mentions}" }

  before do
    # build personal namespaces and routes for users
    mentioned_users.each { |u| u.becomes(User).save! }

    # build namespaces and routes for groups
    mentioned_groups.each do |gr|
      gr.name += '-org'
      gr.path += '-org'
      gr.becomes(Namespace).save!
    end
  end

  context 'mentions in epic description' do
    let(:epic) do
      epics.create!(iid: 1, group_id: group.id, author_id: author.id, title: "epic title @#{author.username}",
                    title_html: "epic title  @#{author.username}", description: description_mentions)
    end

    it 'has correct no_quote_columns' do
      expect(Gitlab::BackgroundMigration::UserMentions::Models::Epic.no_quote_columns).to match([:note_id, :epic_id])
    end

    it 'migrates mentions' do
      join = MigrateEpicMentionsToDb::JOIN
      conditions = MigrateEpicMentionsToDb::QUERY_CONDITIONS

      expect do
        subject.perform('Epic', join, conditions, false, epic.id, epic.id)
      end.to change { epic_user_mentions.count }.by(1)

      epic_user_mention = epic_user_mentions.last
      expect(epic_user_mention.mentioned_users_ids.sort).to eq(mentioned_users.pluck(:id).sort)
      expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
      expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
    end

    context 'mentions in epic notes' do
      let(:epic_note) { notes.create!(noteable_id: epic.id, noteable_type: 'Epic', author_id: author.id, note: description_mentions) }
      let(:epic_note2) { notes.create!(noteable_id: epic.id, noteable_type: 'Epic', author_id: author.id, note: 'sample note') }
      let(:system_epic_note) { notes.create!(noteable_id: epic.id, noteable_type: 'Epic', author_id: author.id, note: description_mentions, system: true) }

      before do
        epic_note.becomes(Note).save!
        epic_note2.becomes(Note).save!
        system_epic_note.becomes(Note).save!
      end

      it 'migrates mentions from note' do
        join = MigrateEpicNotesMentionsToDb::JOIN
        conditions = MigrateEpicNotesMentionsToDb::QUERY_CONDITIONS

        expect do
          subject.perform('Epic', join, conditions, true, Note.minimum(:id), Note.maximum(:id))
        end.to change { epic_user_mentions.where(note_id: epic_note.id).count }.by(1)

        # check that the epic_user_mention for regular note is created
        epic_user_mention = epic_user_mentions.first
        expect(epic_user_mention.becomes(EpicUserMention).note.system).to be false
        expect(epic_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
        expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
        expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)

        # check that the epic_user_mention for system note is created
        epic_user_mention = epic_user_mentions.second
        expect(epic_user_mention.becomes(EpicUserMention).note.system).to be true
        expect(epic_user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
        expect(epic_user_mention.mentioned_groups_ids.sort).to eq([group.id])
        expect(epic_user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)
      end
    end
  end
end
