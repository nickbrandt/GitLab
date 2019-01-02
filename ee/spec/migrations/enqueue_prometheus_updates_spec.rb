# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20181115140251_enqueue_prometheus_updates.rb')

describe EnqueuePrometheusUpdates, :migration, :sidekiq do
  let(:migration) { described_class.new }
  let(:background_migration) { described_class::MIGRATION }
  let(:batch_size_constant) { "#{described_class}::BATCH_SIZE" }
  let(:delay) { described_class::DELAY_INTERVAL }

  let(:clusters) { table(:clusters) }
  let(:prometheus) { table(:clusters_applications_prometheus) }

  describe '#up' do
    around do |example|
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          example.run
        end
      end
    end

    before do
      stub_const(batch_size_constant, 2)
    end

    context 'with prometheus applications' do
      let!(:prometheus1) { create_prometheus }
      let!(:prometheus2) { create_prometheus }
      let!(:prometheus3) { create_prometheus }

      it 'schedules update jobs' do
        migration.up

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(background_migration)
          .to be_scheduled_delayed_migration(delay, prometheus1.id, prometheus2.id)
        expect(background_migration)
          .to be_scheduled_delayed_migration(delay * 2, prometheus3.id, prometheus3.id)
      end
    end

    context 'without prometheus applications' do
      it 'does not schedule update jobs' do
        migration.up

        expect(BackgroundMigrationWorker.jobs.size).to eq(0)
      end
    end

    private

    def create_prometheus
      cluster = clusters.create!(name: 'cluster')

      prometheus.create!(
        cluster_id: cluster.id,
        status: 3,
        version: '1.2.3'
      )
    end
  end
end
