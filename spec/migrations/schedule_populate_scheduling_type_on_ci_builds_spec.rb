# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200227122739_schedule_populate_scheduling_type_on_ci_builds.rb')

describe SchedulePopulateSchedulingTypeOnCiBuilds, :migration do
  let(:builds_table) { table(:ci_builds) }
  let(:migration_class) { Gitlab::BackgroundMigration::PopulateSchedulingTypeOnCiBuilds }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let!(:build_1)        { builds_table.create!(type: 'Ci::Build', scheduling_type: nil) }
  let!(:build_2)        { builds_table.create!(type: 'Ci::Build', scheduling_type: nil) }
  let!(:build_skip_1)   { builds_table.create!(type: 'Ci::Build', scheduling_type: 0) }
  let!(:build_skip_2)   { builds_table.create!(type: 'GenericCommitStatus', scheduling_type: nil) }
  let!(:build_3)        { builds_table.create!(type: 'Ci::Bridge', scheduling_type: nil) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  it 'schedules background migrations at correct time' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(5.minutes, build_1.id, build_1.id)
        expect(migration_name).to be_scheduled_delayed_migration(10.minutes, build_2.id, build_2.id)
        expect(migration_name).to be_scheduled_delayed_migration(15.minutes, build_3.id, build_3.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'correctly processes web hooks', :sidekiq_might_not_need_inline do
    perform_enqueued_jobs do
      expect(builds_table.where(scheduling_type: nil).count).to eq(4)

      migrate!

      expect(builds_table.where(scheduling_type: nil).count).to eq(1)
    end
  end
end
