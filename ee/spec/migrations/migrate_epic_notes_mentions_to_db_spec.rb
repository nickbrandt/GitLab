# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191115115522_migrate_epic_notes_mentions_to_db')

describe MigrateEpicNotesMentionsToDb, :migration, :sidekiq do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }
  let(:notes) { table(:notes) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    users.create!(id: 1, name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0)
    namespaces.create!(id: 1, name: 'group1', path: 'group1', owner_id: 1)
    epics.create!(id: 1, iid: 1, title: "title", title_html: 'title', description: 'epic description', group_id: 1, author_id: 1)

    notes.create!(note: 'note1 for @root to check', noteable_id: 1, noteable_type: 'Epic')
    notes.create!(note: 'note2 for @root to check', noteable_id: 1, noteable_type: 'Epic', system: true)
    notes.create!(note: 'note3 for @root to check', noteable_id: 1, noteable_type: 'Epic')
  end

  it 'schedules epic mentions migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        migration = described_class::MIGRATION
        join = described_class::JOIN
        conditions = described_class::QUERY_CONDITIONS

        expect(migration).to be_scheduled_delayed_migration(2.minutes, 'Epic', join, conditions, true, 1, 1)
        expect(migration).to be_scheduled_delayed_migration(4.minutes, 'Epic', join, conditions, true, 2, 2)
        expect(migration).to be_scheduled_delayed_migration(6.minutes, 'Epic', join, conditions, true, 3, 3)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end
end
