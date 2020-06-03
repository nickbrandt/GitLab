# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignRepositoryShardSyncWorker, :geo, :geo_fdw, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let!(:primary) { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }

  let(:shard_name) { Gitlab.config.repositories.storages.each_key.first }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#perform' do
    let(:restricted_group) { create(:group) }

    let(:unsynced_project_in_restricted_group) { create(:project, group: restricted_group) }
    let(:unsynced_project) { create(:project) }

    before do
      stub_exclusive_lease(renew: true)

      Gitlab::ShardHealthCache.update([shard_name])

      create(:design, project: unsynced_project_in_restricted_group)
      create(:design, project: unsynced_project)
    end

    it 'performs Geo::DesignRepositorySyncWorker for each project' do
      expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'performs Geo::DesignRepositorySyncWorker for designs where last attempt to sync failed' do
      create(:geo_design_registry, :sync_failed, project: unsynced_project_in_restricted_group)
      create(:geo_design_registry, :synced, project: unsynced_project)

      expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async).once.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::DesignRepositorySyncWorker when shard becomes unhealthy' do
      Gitlab::ShardHealthCache.update([])

      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'performs Geo::DesignRepositorySyncWorker for designs updated recently' do
      create(:geo_design_registry, project: unsynced_project_in_restricted_group)
      create(:geo_design_registry, :synced, project: unsynced_project)
      create(:geo_design_registry)

      expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not schedule a job twice for the same project' do
      scheduled_jobs = [
        { job_id: 1, project_id: unsynced_project.id },
        { job_id: 2, project_id: unsynced_project_in_restricted_group.id }
      ]

      is_expected.to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    it 'does not perform Geo::DesignRepositorySyncWorker when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not perform Geo::ProjectSyncWorker when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::DesignRepositorySyncWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    context 'multiple shards' do
      it 'uses two loops to schedule jobs', :sidekiq_might_not_need_inline do
        expect(subject).to receive(:schedule_jobs).twice.and_call_original

        Gitlab::ShardHealthCache.update([shard_name, 'shard2', 'shard3', 'shard4', 'shard5'])
        secondary.update!(repos_max_capacity: 5)

        subject.perform(shard_name)
      end
    end

    context 'when node has namespace restrictions', :request_store do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [restricted_group])

        allow(::Gitlab::Geo).to receive(:current_node).and_call_original
        Rails.cache.write(:current_node, secondary.to_json)
        allow(::GeoNode).to receive(:current_node).and_return(secondary)
      end

      it 'does not perform Geo::DesignRepositorySyncWorker for projects that do not belong to selected namespaces to replicate' do
        expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async)
          .with(unsynced_project_in_restricted_group.id)
          .once
          .and_return(spy)

        subject.perform(shard_name)
      end

      it 'does not perform Geo::DesignRepositorySyncWorker for synced projects updated recently that do not belong to selected namespaces to replicate' do
        create(:geo_design_registry, project: unsynced_project_in_restricted_group)
        create(:geo_design_registry, project: unsynced_project)

        expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async)
          .with(unsynced_project_in_restricted_group.id)
          .once
          .and_return(spy)

        subject.perform(shard_name)
      end
    end
  end
end
