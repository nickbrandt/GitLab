# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerification::Secondary::ShardWorker, :geo, :geo_fdw, :request_store, :clean_gitlab_redis_cache, :use_sql_query_cache_for_tracking_db do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let!(:secondary) { create(:geo_node) }
  let(:shard_name) { Gitlab.config.repositories.storages.each_key.first }
  let(:secondary_single_worker) { Geo::RepositoryVerification::Secondary::SingleWorker }
  let!(:project) { create(:project) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#perform' do
    before do
      stub_exclusive_lease(renew: true)

      Gitlab::ShardHealthCache.update([shard_name])
    end

    context 'shard worker scheduler' do
      it 'acquires lock namespacing it per shard name' do
        subject.perform(shard_name)

        expect(subject.lease_key).to include(shard_name)
      end
    end

    it 'schedule a job for each project' do
      other_project = create(:project)
      create(:repository_state, :repository_verified, project: project)
      create(:repository_state, :repository_verified, project: other_project)
      create(:geo_project_registry, :synced, :repository_verification_outdated, project: project)
      create(:geo_project_registry, :synced, :repository_verification_outdated, project: other_project)

      expect(secondary_single_worker).to receive(:perform_async).twice

      subject.perform(shard_name)
    end

    it 'schedule jobs for projects missing repository verification' do
      create(:repository_state, :repository_verified, :wiki_verified, project: project)
      missing_repository_verification = create(:geo_project_registry, :synced, :wiki_verified, project: project)

      expect(secondary_single_worker).to receive(:perform_async).with(missing_repository_verification.id)

      subject.perform(shard_name)
    end

    it 'schedule jobs for projects missing wiki verification' do
      create(:repository_state, :repository_verified, :wiki_verified, project: project)
      missing_wiki_verification = create(:geo_project_registry, :synced, :repository_verified, project: project)

      expect(secondary_single_worker).to receive(:perform_async).with(missing_wiki_verification.id)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs for projects on other shards' do
      project_other_shard = create(:project)
      project_other_shard.update_column(:repository_storage, 'other')
      create(:repository_state, :repository_verified, :wiki_verified, project: project_other_shard)
      registry_other_shard = create(:geo_project_registry, :synced, :wiki_verified, project: project_other_shard)

      expect(secondary_single_worker).not_to receive(:perform_async).with(registry_other_shard.id)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs for projects missing repositories on primary' do
      other_project = create(:project)
      create(:repository_state, :repository_verified, project: project)
      create(:repository_state, :wiki_verified, project: other_project)
      create(:geo_project_registry, :synced, project: project, repository_missing_on_primary: true)
      create(:geo_project_registry, :synced, project: other_project, wiki_missing_on_primary: true)

      expect(secondary_single_worker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    # test that when jobs are always moving forward and we're not querying the same things
    # over and over
    describe 'resource loading' do
      before do
        allow(subject).to receive(:db_retrieve_batch_size) { 1 }
      end

      let(:project1_repo_verified) { create(:repository_state, :repository_verified).project }
      let(:project2_repo_verified) { create(:repository_state, :repository_verified).project }
      let(:project3_repo_failed) { create(:repository_state, :repository_failed).project }
      let(:project4_wiki_verified) { create(:repository_state, :wiki_verified).project }
      let(:project5_both_verified) { create(:repository_state, :repository_verified, :wiki_verified).project }
      let(:project6_both_verified) { create(:repository_state, :repository_verified, :wiki_verified).project }

      it 'handles multiple batches of projects needing verification' do
        reg1 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: project1_repo_verified)
        reg2 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: project2_repo_verified)

        expect(secondary_single_worker).to receive(:perform_async).with(reg1.id).once.and_call_original
        expect(secondary_single_worker).to receive(:perform_async).with(reg2.id).once.and_call_original

        3.times do
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end

      it 'handles multiple batches of projects needing verification, skipping failed repos' do
        reg1 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: project1_repo_verified)
        reg2 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: project2_repo_verified)
        create(:geo_project_registry, :synced, :repository_verification_outdated, project: project3_repo_failed)
        reg4 = create(:geo_project_registry, :synced, :wiki_verification_outdated, project: project4_wiki_verified)
        create(:geo_project_registry, :synced, :repository_verification_failed, :wiki_verification_failed, project: project5_both_verified)
        reg6 = create(:geo_project_registry, :synced, project: project6_both_verified)

        expect(secondary_single_worker).to receive(:perform_async).with(reg1.id).once.and_call_original
        expect(secondary_single_worker).to receive(:perform_async).with(reg2.id).once.and_call_original
        expect(secondary_single_worker).to receive(:perform_async).with(reg4.id).once.and_call_original
        expect(secondary_single_worker).to receive(:perform_async).with(reg6.id).once.and_call_original

        7.times do
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end
    end

    it 'does not schedule jobs when shard becomes unhealthy' do
      create(:repository_state, project: project)

      Gitlab::ShardHealthCache.update([])

      expect(secondary_single_worker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(secondary_single_worker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not schedule jobs when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(secondary_single_worker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when number of scheduled jobs exceeds capacity' do
      create(:project)

      is_expected.to receive(:scheduled_job_ids).and_return(1..1000).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    context 'backoff time' do
      let(:cache_key) { "#{described_class.name.underscore}:shard:#{shard_name}:skip" }

      before do
        allow(Rails.cache).to receive(:write).and_call_original
        allow(Rails.cache).to receive(:read).and_call_original
      end

      it 'sets the back off time when there are no pending items' do
        expect(Rails.cache).to receive(:write).with(cache_key, true, expires_in: 300.seconds).once

        subject.perform(shard_name)
      end

      it 'does not perform Geo::RepositoryVerification::Secondary::SingleWorker when the backoff time is set' do
        create(:repository_state, :repository_verified, project: project)
        create(:geo_project_registry, :synced, :repository_verification_outdated, project: project)

        expect(Rails.cache).to receive(:read).with(cache_key).and_return(true)

        expect(Geo::RepositoryVerification::Secondary::SingleWorker).not_to receive(:perform_async)

        subject.perform(shard_name)
      end
    end
  end
end
