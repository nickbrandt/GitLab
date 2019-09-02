# frozen_string_literal: true

require 'spec_helper'

describe Geo::Secondary::RepositoryBackfillWorker, :geo, :geo_fdw, :clean_gitlab_redis_cache do
  include EE::GeoHelpers

  let(:primary) { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node, repos_max_capacity: 5) }
  let(:shard_name) { Gitlab.config.repositories.storages.keys.first }

  before do
    stub_current_geo_node(secondary)
    stub_healthy_shards(shard_name)
  end

  describe '#perform' do
    it 'does not schedule jobs when Geo database is not configured' do
      create(:project)

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      with_no_geo_database_configured do
        subject.perform(shard_name)
      end
    end

    it 'does not schedule jobs when not running on a Geo secondary node' do
      stub_current_geo_node(primary)
      create(:project)

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when shard is not healthy' do
      stub_healthy_shards([])
      create(:project)

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when the Geo secondary node is disabled' do
      stub_node_disabled(secondary)
      create(:project)

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs for projects on other shards' do
      project = create(:project)
      project.update_column(:repository_storage, 'other')

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'schedules a job for each unsynced project' do
      create_list(:project, 2)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(true)

      subject.perform(shard_name)
    end

    it 'respects Geo secondary node max capacity per shard' do
      stub_healthy_shards([shard_name, 'shard2', 'shard3', 'shard4', 'shard5'])
      allow(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return('jid-123')
      create_list(:project, 2)

      expect(subject).to receive(:sleep).twice.and_call_original

      subject.perform(shard_name)
    end
  end
end
