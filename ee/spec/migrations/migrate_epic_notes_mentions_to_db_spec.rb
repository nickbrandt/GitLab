# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191115115522_migrate_epic_notes_mentions_to_db')

describe MigrateEpicNotesMentionsToDb, :migration do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }
  let(:notes) { table(:notes) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id, type: 'Group') }
  let(:epic) { epics.create!(iid: 1, title: "title", title_html: 'title', description: 'epic description', group_id: group.id, author_id: user.id) }
  let!(:resource1) { notes.create!(note: 'note1 for @root to check', noteable_id: epic.id, noteable_type: 'Epic') }
  let!(:resource2) { notes.create!(note: 'note2 for @root to check', noteable_id: epic.id, noteable_type: 'Epic', system: true) }
  let!(:resource3) { notes.create!(note: 'note3 for @root to check', noteable_id: epic.id, noteable_type: 'Epic') }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it_behaves_like 'schedules resource mentions migration', Epic, true
end
