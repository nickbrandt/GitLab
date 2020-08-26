# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactRegistryFinder, :geo do
  before do
    stub_artifacts_object_storage
  end

  let_it_be(:project) { create(:project) }

  let_it_be(:ci_job_artifact_1) { create(:ci_job_artifact, project: project) }
  let_it_be(:ci_job_artifact_2) { create(:ci_job_artifact, project: project) }
  let_it_be(:ci_job_artifact_3) { create(:ci_job_artifact, project: project) }
  let_it_be(:ci_job_artifact_4) { create(:ci_job_artifact, project: project) }
  let_it_be(:ci_job_artifact_5) { create(:ci_job_artifact, project: project) }
  let!(:ci_job_artifact_remote_1) { create(:ci_job_artifact, :remote_store, project: project) }
  let!(:ci_job_artifact_remote_2) { create(:ci_job_artifact, :remote_store, project: project) }
  let!(:ci_job_artifact_remote_3) { create(:ci_job_artifact, :remote_store, project: project) }

  let_it_be(:registry_ci_job_artifact_1) { create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id) }
  let_it_be(:registry_ci_job_artifact_2) { create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true) }
  let_it_be(:registry_ci_job_artifact_3) { create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id) }
  let_it_be(:registry_ci_job_artifact_4) { create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id) }
  let_it_be(:registry_ci_job_artifact_5) { create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago) }
  let!(:registry_ci_job_artifact_remote_1) { create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id) }
  let!(:registry_ci_job_artifact_remote_2) { create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true) }
  let!(:registry_ci_job_artifact_remote_3) { create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id) }

  describe '#registry_count' do
    it 'counts registries for job artifacts' do
      expect(subject.registry_count).to eq 8
    end
  end

  describe '#synced_count' do
    it 'counts registries that has been synced' do
      expect(subject.synced_count).to eq 2
    end
  end

  describe '#failed_count' do
    it 'counts registries that sync has failed' do
      expect(subject.failed_count).to eq 4
    end
  end

  describe '#synced_missing_on_primary_count' do
    it 'counts registries that have been synced and are missing on the primary, excluding not synced ones' do
      expect(subject.synced_missing_on_primary_count).to eq 2
    end
  end

  describe '#find_unsynced_registries' do
    it 'returns registries for job artifacts that have never been synced' do
      registries = subject.find_unsynced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_ci_job_artifact_3, registry_ci_job_artifact_remote_3)
    end

    it 'excludes except_ids' do
      registries = subject.find_unsynced_registries(batch_size: 10, except_ids: [ci_job_artifact_3.id])

      expect(registries).to match_ids(registry_ci_job_artifact_remote_3)
    end
  end

  describe '#find_failed_registries' do
    it 'returns registries for job artifacts that have failed to sync' do
      registries = subject.find_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_ci_job_artifact_1, registry_ci_job_artifact_4, registry_ci_job_artifact_remote_1, registry_ci_job_artifact_remote_2)
    end

    it 'excludes except_ids' do
      registries = subject.find_failed_registries(batch_size: 10, except_ids: [ci_job_artifact_4.id, ci_job_artifact_remote_2.id])

      expect(registries).to match_ids(registry_ci_job_artifact_1, registry_ci_job_artifact_remote_1)
    end
  end

  describe '#find_retryable_synced_missing_on_primary_registries' do
    it 'returns registries for job artifacts that have been synced and are missing on the primary' do
      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

      expect(registries).to match_ids(registry_ci_job_artifact_2, registry_ci_job_artifact_5)
    end

    it 'excludes except_ids' do
      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10, except_ids: [ci_job_artifact_5.id])

      expect(registries).to match_ids(registry_ci_job_artifact_2)
    end
  end

  it_behaves_like 'a file registry finder'
end
