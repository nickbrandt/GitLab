require 'spec_helper'

require Rails.root.join('db', 'post_migrate', '20200806100713_schedule_populate_resolved_on_default_branch_column.rb')

RSpec.describe SchedulePopulateResolvedOnDefaultBranchColumn do
  before do
    allow_any_instance_of(Gitlab).to receive(:ee?).and_return(ee?)
  end

  around do |example|
    Timecop.freeze { Sidekiq::Testing.fake! { example.run } }
  end

  context 'when the Gitlab instance is CE' do
    let(:ee?) { false }

    it 'does not run the migration' do
      expect { migrate! }.not_to change { BackgroundMigrationWorker.jobs.size }
    end
  end

  context 'when the Gitlab instance is EE' do
    let(:ee?) { true }
    let!(:project_1) { create(:project) }
    let!(:project_2) { create(:project) }
    let!(:project_3) { create(:project) }

    before do
      create(:vulnerability, project: project_1)
      create(:vulnerability, project: project_2)

      stub_const("#{described_class.name}::BATCH_SIZE", 1)
    end

    it 'schedules the background jobs', :aggregate_failures do
      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to be(2)
      expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(2.minutes, project_1.id)
      expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(4.minutes, project_2.id)
    end
  end
end
