# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Secondary::RegistryConsistencyWorker, :geo, :geo_fdw do
  include EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let(:primary) { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  let(:worker_class) { described_class }

  it_behaves_like 'reenqueuer'

  it 'uses a cronjob queue' do
    expect(subject.sidekiq_options_hash).to include(
      'queue' => 'cronjob:geo_secondary_registry_consistency',
      'queue_namespace' => :cronjob
    )
  end

  describe '#perform' do
    before do
      allow(subject).to receive(:sleep) # faster tests
    end

    it_behaves_like 'it is rate limited to 1 call per', 5.seconds do
      let(:rate_limited_method) { subject.perform }
    end

    context 'when RegistryConsistencyService#execute returns true at least once' do
      before do
        described_class::REGISTRY_CLASSES.each_with_index do |registry_class, index|
          first_one = index == 0
          service = double
          expect(Geo::RegistryConsistencyService).to receive(:new).with(registry_class, batch_size: 1000).and_return(service)
          expect(service).to receive(:execute).and_return(first_one)
        end
      end

      it 'returns true' do
        expect(subject.perform).to be_truthy
      end

      it 'RegistryConsistencyWorker gets reenqueued' do
        expect(Geo::Secondary::RegistryConsistencyWorker).to receive(:perform_async)

        subject.perform
      end
    end

    context 'when RegistryConsistencyService#execute returns false for all registry classes' do
      before do
        described_class::REGISTRY_CLASSES.each do |registry_class|
          service = double
          expect(Geo::RegistryConsistencyService).to receive(:new).with(registry_class, batch_size: 1000).and_return(service)
          expect(service).to receive(:execute).and_return(false)
        end
      end

      it 'returns false' do
        expect(subject.perform).to be_falsey
      end

      it 'RegistryConsistencyWorker does not get reenqueued (we will wait until next cronjob)' do
        expect(Geo::Secondary::RegistryConsistencyWorker).not_to receive(:perform_async)

        subject.perform
      end
    end

    # Somewhat of an integration test
    it 'creates missing registries for each registry class' do
      lfs_object = create(:lfs_object)
      job_artifact = create(:ci_job_artifact)
      upload = create(:upload)

      expect(Geo::LfsObjectRegistry.where(lfs_object_id: lfs_object.id).count).to eq(0)
      expect(Geo::JobArtifactRegistry.where(artifact_id: job_artifact.id).count).to eq(0)
      expect(Geo::UploadRegistry.where(file_id: upload.id).count).to eq(0)

      subject.perform

      expect(Geo::LfsObjectRegistry.where(lfs_object_id: lfs_object.id).count).to eq(1)
      expect(Geo::JobArtifactRegistry.where(artifact_id: job_artifact.id).count).to eq(1)
      expect(Geo::UploadRegistry.where(file_id: upload.id).count).to eq(1)
    end

    context 'when geo_job_artifact_registry_ssot_sync is disabled' do
      let_it_be(:job_artifact) { create(:ci_job_artifact) }

      before do
        stub_feature_flags(geo_job_artifact_registry_ssot_sync: false)
      end

      it 'returns false' do
        expect(subject.perform).to be_falsey
      end

      it 'does not execute RegistryConsistencyService for Job Artifacts' do
        allow(Geo::RegistryConsistencyService).to receive(:new).with(Geo::LfsObjectRegistry, batch_size: 1000).and_call_original
        allow(Geo::RegistryConsistencyService).to receive(:new).with(Geo::UploadRegistry, batch_size: 1000).and_call_original

        expect(Geo::RegistryConsistencyService).not_to receive(:new).with(Geo::JobArtifactRegistry, batch_size: 1000)

        subject.perform
      end
    end

    context 'when geo_file_registry_ssot_sync is disabled' do
      let_it_be(:upload) { create(:upload) }

      before do
        stub_feature_flags(geo_file_registry_ssot_sync: false)
      end

      it 'returns false' do
        expect(subject.perform).to be_falsey
      end

      it 'does not execute RegistryConsistencyService for Uploads' do
        allow(Geo::RegistryConsistencyService).to receive(:new).with(Geo::JobArtifactRegistry, batch_size: 1000).and_call_original
        allow(Geo::RegistryConsistencyService).to receive(:new).with(Geo::LfsObjectRegistry, batch_size: 1000).and_call_original

        expect(Geo::RegistryConsistencyService).not_to receive(:new).with(Geo::UploadRegistry, batch_size: 1000)

        subject.perform
      end
    end

    context 'when the current Geo node is disabled or primary' do
      before do
        stub_primary_node
      end

      it 'returns false' do
        expect(subject.perform).to be_falsey
      end

      it 'does not execute RegistryConsistencyService' do
        expect(Geo::RegistryConsistencyService).not_to receive(:new)

        subject.perform
      end
    end
  end
end
