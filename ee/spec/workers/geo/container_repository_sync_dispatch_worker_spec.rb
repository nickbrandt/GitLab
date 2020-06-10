# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositorySyncDispatchWorker, :geo, :geo_fdw, :use_sql_query_cache_for_tracking_db do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let(:primary)   { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:over_time?).and_return(false)
    end
    stub_registry_replication_config(enabled: true)
  end

  it 'does not schedule anything when tracking database is not configured' do
    create(:container_repository)

    allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

    expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

    subject.perform

    # We need to unstub here or the DatabaseCleaner will have issues since it
    # will appear as though the tracking DB were not available
    allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
  end

  it 'does not schedule anything when node is disabled' do
    create(:container_repository)

    secondary.enabled = false
    secondary.save

    expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

    subject.perform
  end

  context 'Sync condition' do
    let(:container_repository) { create(:container_repository) }

    it 'performs Geo::ContainerRepositorySyncWorker' do
      expect(Geo::ContainerRepositorySyncWorker).to receive(:perform_async).with(container_repository.id)

      subject.perform
    end

    it 'performs Geo::ContainerRepositorySyncWorker for failed syncs' do
      container_repository_registry = create(:container_repository_registry, :sync_failed)

      expect(Geo::ContainerRepositorySyncWorker).to receive(:perform_async)
        .with(container_repository_registry.container_repository_id).once.and_return(spy)

      subject.perform
    end

    it 'does not perform Geo::ContainerRepositorySyncWorker for synced repositories' do
      create(:container_repository_registry, :synced)

      expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform
    end

    context 'with a failed sync' do
      let(:failed_registry) { create(:container_repository_registry, :sync_failed) }

      it 'does not stall backfill' do
        unsynced = create(:container_repository)

        stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 1)

        expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async).with(failed_registry.container_repository_id)
        expect(Geo::ContainerRepositorySyncWorker).to receive(:perform_async).with(unsynced.id)

        subject.perform
      end

      it 'does not retry failed files when retry_at is tomorrow' do
        failed_registry = create(:container_repository_registry, :sync_failed, retry_at: Date.tomorrow)

        expect(Geo::ContainerRepositorySyncWorker)
          .not_to receive(:perform_async).with( failed_registry.container_repository_id)

        subject.perform
      end

      it 'retries failed files when retry_at is in the past' do
        failed_registry = create(:container_repository_registry, :sync_failed, retry_at: Date.yesterday)

        expect(Geo::ContainerRepositorySyncWorker)
          .to receive(:perform_async).with(failed_registry.container_repository_id)

        subject.perform
      end
    end
  end

  context 'when node has namespace restrictions', :request_store do
    let(:synced_group) { create(:group) }
    let(:project_in_synced_group) { create(:project, group: synced_group) }
    let(:unsynced_project) { create(:project) }

    before do
      secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

      allow(ProjectCacheWorker).to receive(:perform_async).and_return(true)
      allow(::Gitlab::Geo).to receive(:current_node).and_call_original
      Rails.cache.write(:current_node, secondary.to_json)
      allow(::GeoNode).to receive(:current_node).and_return(secondary)
    end

    it 'does not perform Geo::ContainerRepositorySyncWorker for repositories that does not belong to selected namespaces ' do
      container_repository = create(:container_repository, project: project_in_synced_group)
      create(:container_repository, project: unsynced_project)

      expect(Geo::ContainerRepositorySyncWorker).to receive(:perform_async)
        .with(container_repository.id).once.and_return(spy)

      subject.perform
    end
  end
end
