# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200214173000_cleanup_empty_epic_user_mentions')

describe CleanupEmptyEpicUserMentions, :migration, :sidekiq do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }
  let(:notes) { table(:notes) }
  let(:epic_user_mentions) { table(:epic_user_mentions) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id, type: 'Group') }
  let(:epic) { epics.create!(iid: 1, title: "title", title_html: 'title', description: 'epic description', group_id: group.id, author_id: user.id) }

  # migrateable resources
  let!(:resource1) { notes.create!(note: 'note1 for @root to check', noteable_id: epic.id, noteable_type: 'Epic') }
  let!(:resource2) { notes.create!(note: 'note2 for @root to check', noteable_id: epic.id, noteable_type: 'Epic', system: true) }
  let!(:resource3) { notes.create!(note: 'note3 for @root to check', noteable_id: epic.id, noteable_type: 'Epic') }

  # non-migrateable resources
  # this note is already migrated, as it has a record in the epic_user_mentions table
  let!(:resource4) { notes.create!(note: 'note3 for @root to check', noteable_id: epic.id, noteable_type: 'Epic') }
  let!(:user_mention) { epic_user_mentions.create!(epic_id: epic.id, note_id: resource4.id, mentioned_users_ids: [1]) }

  # these should get cleanup, by the migration
  let!(:blank_epic_user_mention1) { epic_user_mentions.create!(epic_id: epic.id, note_id: resource1.id)}
  let!(:blank_epic_user_mention2) { epic_user_mentions.create!(epic_id: epic.id, note_id: resource2.id)}
  let!(:blank_epic_user_mention3) { epic_user_mentions.create!(epic_id: epic.id, note_id: resource3.id)}

  it 'cleans blank user mentions' do
    expect(epic_user_mentions.count).to eq 4

    migrate!

    expect(epic_user_mentions.count).to eq 1
  end
end
