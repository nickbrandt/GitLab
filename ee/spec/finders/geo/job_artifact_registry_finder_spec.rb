require 'spec_helper'

describe Geo::JobArtifactRegistryFinder, :geo_fdw do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction of a
  # different connection.
  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project) }
  let(:project_broken_storage) { create(:project, :broken_storage) }

  subject { described_class.new(current_node_id: secondary.id) }

  before do
    stub_current_geo_node(secondary)
    stub_artifacts_object_storage
  end

  let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
  let!(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
  let!(:job_artifact_3) { create(:ci_job_artifact, project: project_broken_storage) }
  let!(:job_artifact_4) { create(:ci_job_artifact, project: project_broken_storage) }
  let!(:job_artifact_5) { create(:ci_job_artifact, :expired, project: synced_project) }
  let!(:job_artifact_6) { create(:ci_job_artifact, :expired, project: project_broken_storage) }
  let!(:job_artifact_remote_1) { create(:ci_job_artifact, :remote_store, project: synced_project) }
  let!(:job_artifact_remote_2) { create(:ci_job_artifact, :remote_store, project: unsynced_project) }
  let!(:job_artifact_remote_3) { create(:ci_job_artifact, :expired, :remote_store, project: project_broken_storage) }

  context 'counts all the things' do
    describe '#count_syncable' do
      it 'counts non-expired job artifacts' do
        expect(subject.count_syncable).to eq 6
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts non-expired job artifacts' do
          expect(subject.count_syncable).to eq 2
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts non-expired job artifacts' do
          expect(subject.count_syncable).to eq 2
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage) }

        it 'counts non-expired job artifacts' do
          expect(subject.count_syncable).to eq 4
        end
      end
    end

    describe '#count_synced' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_4.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
      end

      context 'without selective sync' do
        it 'counts job artifacts that have been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 3
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts job artifacts that has been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 1
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts job artifacts that has been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage) }

        it 'counts job artifacts that has been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 2
        end
      end
    end

    describe '#count_failed' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_3.id, success: false)
      end

      context 'without selective sync' do
        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 3
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 2
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage) }

        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 2
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false, missing_on_primary: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_4.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id, missing_on_primary: false)
      end

      context 'without selective sync' do
        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 2
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage) }

        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end
    end

    describe '#count_registry' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_4.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)
      end

      it 'counts file registries for job artifacts' do
        expect(subject.count_registry).to eq 4
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 4
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 4
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage) }

        it 'counts file registries for job artifacts ignoring remote artifacts' do
          expect(subject.count_registry).to eq 4
        end
      end
    end
  end

  context 'finds all the things' do
    describe '#find_unsynced' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id, success: true)
      end

      context 'without selective sync' do
        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10, except_artifact_ids: [job_artifact_2.id])

          expect(job_artifacts).to match_ids(job_artifact_remote_1, job_artifact_remote_2, job_artifact_4)
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_1)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_4)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones and remotes' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_2, job_artifact_4)
        end
      end
    end

    describe '#find_migrated_local' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_3.id)
      end

      it 'returns job artifacts excluding ones from the exception list' do
        job_artifacts = subject.find_migrated_local(batch_size: 10, except_artifact_ids: [job_artifact_remote_1.id])

        expect(job_artifacts).to match_ids(job_artifact_remote_2, job_artifact_remote_3)
      end

      it 'includes synced job artifacts that are expired, exclude stored locally' do
        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_remote_1, job_artifact_remote_2, job_artifact_remote_3)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns job artifacts remotely and successfully synced locally' do
          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_1)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns job artifacts remotely and successfully synced locally' do
          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_3)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage) }

        it 'returns job artifacts excluding ones from the exception list' do
          job_artifacts = subject.find_migrated_local(batch_size: 10, except_artifact_ids: [job_artifact_remote_1.id])

          expect(job_artifacts).to match_ids(job_artifact_remote_2, job_artifact_remote_3)
        end
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
