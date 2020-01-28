# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191115115043_migrate_epic_mentions_to_db')

describe MigrateEpicMentionsToDb, :migration, :sidekiq do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    users.create!(id: 1, name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0)
    namespaces.create!(id: 1, name: 'group1', path: 'group1', owner_id: 1)
    epics.create!(id: 1, iid: 1, title: "title1", title_html: 'title1', description: 'epic description with @root mention', group_id: 1, author_id: 1)
    epics.create!(id: 2, iid: 2, title: "title2", title_html: "title2", description: 'epic description with @group mention', group_id: 1, author_id: 1)
    epics.create!(id: 3, iid: 3, title: "title3", title_html: "title3", description: 'epic description with @project mention', group_id: 1, author_id: 1)
  end

  it 'schedules epic mentions migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        migration = described_class::MIGRATION
        join = described_class::JOIN
        conditions = described_class::QUERY_CONDITIONS

        expect(migration).to be_scheduled_delayed_migration(2.minutes, 'Epic', join, conditions, false, 1, 1)
        expect(migration).to be_scheduled_delayed_migration(4.minutes, 'Epic', join, conditions, false, 2, 2)
        expect(migration).to be_scheduled_delayed_migration(6.minutes, 'Epic', join, conditions, false, 3, 3)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end
end
