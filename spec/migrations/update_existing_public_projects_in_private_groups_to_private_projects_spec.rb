# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191024125120_update_existing_public_projects_in_private_groups_to_private_projects.rb')

describe UpdateExistingPublicProjectsInPrivateGroupsToPrivateProjects, :migration, :sidekiq do
  let(:migration_class) { described_class::MIGRATION }
  let(:migration_name)  { migration_class.to_s.demodulize }

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(migration_name).to be_scheduled_migration(described_class::PRIVATE)
        expect(migration_name).to be_scheduled_migration(described_class::INTERNAL)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
