# frozen_string_literal: true

require 'spec_helper'
require './db/post_migrate/20191115115043_migrate_epic_mentions_to_db'
require './db/post_migrate/20191115115522_migrate_epic_notes_mentions_to_db'

describe Gitlab::BackgroundMigration::UserMentions::CreateResourceUserMention do
  include MigrationsHelpers

  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:notes) { table(:notes) }

  let(:author) { users.create!(email: 'author@example.com', notification_email: 'author@example.com', name: 'author', username: 'author', projects_limit: 10, state: 'active') }
  let(:member) { users.create!(email: 'member@example.com', notification_email: 'member@example.com', name: 'member', username: 'member', projects_limit: 10, state: 'active') }
  let(:admin) { users.create!(email: 'administrator@example.com', notification_email: 'administrator@example.com', name: 'administrator', username: 'administrator', admin: 1, projects_limit: 10, state: 'active') }
  let(:john_doe) { users.create!(email: 'john_doe@example.com', notification_email: 'john_doe@example.com', name: 'john_doe', username: 'john_doe', projects_limit: 10, state: 'active') }
  let(:skipped) { users.create!(email: 'skipped@example.com', notification_email: 'skipped@example.com', name: 'skipped', username: 'skipped', projects_limit: 10, state: 'active') }

  let(:mentioned_users) { [author, member, admin, john_doe, skipped] }
  let(:mentioned_users_refs) { mentioned_users.map { |u| "@#{u.username}" }.join(' ') }

  let(:group) { namespaces.create!(name: 'test1', path: 'test1', runners_token: 'my-token1', project_creation_level: 1, visibility_level: 20, type: 'Group') }
  let(:inaccessible_group) { namespaces.create!(name: 'test2', path: 'test2', runners_token: 'my-token2', project_creation_level: 1, visibility_level: 0, type: 'Group') }
  let(:project) { projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }

  let(:mentioned_groups) { [group, inaccessible_group] }
  let(:group_mentions) { [group, inaccessible_group].map { |gr| "@#{gr.path}" }.join(' ') }
  let(:description_mentions) { "description with mentions #{mentioned_users_refs} and #{group_mentions}" }

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

  describe 'epic mentions' do
    let(:epics) { table(:epics) }
    let(:epic_user_mentions) { table(:epic_user_mentions) }

    context 'mentions in epic description' do
      let!(:epic) do
        epics.create!(iid: 1, group_id: group.id, author_id: author.id, title: "epic title @#{author.username}",
                      title_html: "epic title  @#{author.username}", description: description_mentions)
      end
      let!(:epic_without_mentions) do
        epics.create!(iid: 2, group_id: group.id, author_id: author.id, title: "epic title}",
                      title_html: "epic title", description: 'simple description')
      end

      let(:user_mentions) { epic_user_mentions }
      let(:resource) { epic }

      it_behaves_like 'resource mentions migration', MigrateEpicMentionsToDb, Epic

      it 'has correct no_quote_columns' do
        expect(Gitlab::BackgroundMigration::UserMentions::Models::Epic.no_quote_columns).to match([:note_id, :epic_id])
      end

      context 'mentions in epic notes' do
        let(:note1) { notes.create!(noteable_id: epic.id, noteable_type: 'Epic', author_id: author.id, note: description_mentions) }
        let(:note2) { notes.create!(noteable_id: epic.id, noteable_type: 'Epic', author_id: author.id, note: 'sample note') }
        let(:note3) { notes.create!(noteable_id: epic.id, noteable_type: 'Epic', author_id: author.id, note: description_mentions, system: true) }
        let!(:note4) { notes.create!(noteable_id: epics.maximum(:id) + 10, noteable_type: 'Epic', author_id: author.id, note: description_mentions, project_id: project.id) }

        it_behaves_like 'resource notes mentions migration', MigrateEpicNotesMentionsToDb, Epic
      end
    end
  end
end
