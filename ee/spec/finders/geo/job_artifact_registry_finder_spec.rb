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

  context 'counts all the things' do
    describe '#count_syncable' do
      let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_3) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
      let!(:job_artifact_6) { create(:ci_job_artifact, project: project_broken_storage) }

      it 'counts job artifacts' do
        expect(subject.count_syncable).to eq 6
      end

      it 'ignores remote job artifacts' do
        job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

        expect(subject.count_syncable).to eq 5
      end

      it 'ignores expired job artifacts' do
        job_artifact_1.update_column(:expire_at, Date.yesterday)

        expect(subject.count_syncable).to eq 5
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts job artifacts' do
          expect(subject.count_syncable).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_syncable).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)

          expect(subject.count_syncable).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts job artifacts' do
          expect(subject.count_syncable).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_syncable).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_5.update_column(:expire_at, Date.yesterday)

          expect(subject.count_syncable).to eq 1
        end
      end
    end

    describe '#count_synced' do
      let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_3) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
      let!(:job_artifact_6) { create(:ci_job_artifact, project: project_broken_storage) }

      context 'without selective sync' do
        before do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)
        end

        it 'counts job artifacts that have been synced' do
          expect(subject.count_synced).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_2.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_2.update_column(:expire_at, Date.yesterday)

          expect(subject.count_synced).to eq 1
        end
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)
        end

        it 'counts job artifacts that has been synced' do
          expect(subject.count_synced).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)

          expect(subject.count_synced).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id)
        end

        it 'counts job artifacts that has been synced' do
          expect(subject.count_synced).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_5.update_column(:expire_at, Date.yesterday)

          expect(subject.count_synced).to eq 1
        end
      end
    end

    describe '#count_failed' do
      let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_3) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
      let!(:job_artifact_6) { create(:ci_job_artifact, project: project_broken_storage) }

      context 'without selective sync' do
        before do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, success: false)
        end

        it 'counts job artifacts that sync has failed' do
          expect(subject.count_failed).to eq 3
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_failed).to eq 2
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)

          expect(subject.count_failed).to eq 2
        end
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, success: false)
        end

        it 'counts job artifacts that sync has failed' do
          expect(subject.count_failed).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_failed).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)

          expect(subject.count_failed).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id, success: false)
        end

        it 'counts job artifacts that sync has failed' do
          expect(subject.count_failed).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_failed).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_5.update_column(:expire_at, Date.yesterday)

          expect(subject.count_failed).to eq 1
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_3) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
      let!(:job_artifact_6) { create(:ci_job_artifact, project: project_broken_storage) }

      context 'without selective sync' do
        before do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false, missing_on_primary: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_4.id, missing_on_primary: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id)
        end

        it 'counts job artifacts that have been synced and are missing on the primary' do
          expect(subject.count_synced_missing_on_primary).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_3.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_3.update_column(:expire_at, Date.yesterday)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_4.id, missing_on_primary: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id)
        end

        it 'counts job artifacts that have been synced and are missing on the primary' do
          expect(subject.count_synced_missing_on_primary).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_4.id, missing_on_primary: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id, missing_on_primary: true)
        end

        it 'counts job artifacts that have been synced and are missing on the primary' do
          expect(subject.count_synced_missing_on_primary).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_5.update_column(:expire_at, Date.yesterday)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end
    end

    describe '#count_registry' do
      let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_3) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
      let!(:job_artifact_6) { create(:ci_job_artifact, project: project_broken_storage) }

      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_4.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_6.id)
      end

      it 'counts file registries for job artifacts' do
        expect(subject.count_registry).to eq 4
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 4
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 4
        end
      end
    end
  end

  context 'finds all the things' do
    describe '#find_unsynced' do
      let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_3) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
      let!(:job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
      let!(:job_artifact_6) { create(:ci_job_artifact, project: project_broken_storage) }

      context 'without selective sync' do
        before do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)
        end

        it 'returns job artifacts without an entry on the tracking database' do
          job_artifacts = subject.find_unsynced(batch_size: 10, except_artifact_ids: [job_artifact_2.id])

          expect(job_artifacts).to match_ids(job_artifact_4, job_artifact_5, job_artifact_6)
        end

        it 'ignores remote job artifacts' do
          job_artifact_4.update_column(:file_store, ObjectStorage::Store::REMOTE)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_2, job_artifact_5, job_artifact_6)
        end

        it 'ignores expired job artifacts' do
          job_artifact_5.update_column(:expire_at, Date.yesterday)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_2, job_artifact_4, job_artifact_6)
        end
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'returns job artifacts without an entry on the tracking database' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: true)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_3)
        end

        it 'ignores remote job artifacts' do
          job_artifact_3.update_column(:file_store, ObjectStorage::Store::REMOTE)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_1)
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_3)
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'returns job artifacts without an entry on the tracking database' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_5.id, success: true)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_6)
        end

        it 'ignores remote job artifacts' do
          job_artifact_6.update_column(:file_store, ObjectStorage::Store::REMOTE)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_5)
        end

        it 'ignores expired job artifacts' do
          job_artifact_5.update_column(:expire_at, Date.yesterday)

          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_6)
        end
      end
    end

    describe '#find_migrated_local' do
      let!(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let!(:job_artifact_remote_1) { create(:ci_job_artifact, :remote_store, project: synced_project) }
      let!(:job_artifact_remote_2) { create(:ci_job_artifact, :remote_store, project: unsynced_project) }
      let!(:job_artifact_remote_3) { create(:ci_job_artifact, :remote_store, project: project_broken_storage, expire_at: Date.yesterday) }

      it 'returns job artifacts remotely and successfully synced locally' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)

        job_artifacts = subject.find_migrated_local(batch_size: 10, except_artifact_ids: [job_artifact_remote_1.id])

        expect(job_artifacts).to match_ids(job_artifact_remote_2)
      end

      it 'excludes synced job artifacts that are stored locally' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)

        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_remote_1, job_artifact_remote_2)
      end

      it 'includes synced job artifacts that are expired' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_3.id)

        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_remote_3)
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'returns job artifacts remotely and successfully synced locally' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)

          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_1)
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'returns job artifacts remotely and successfully synced locally' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_3.id)

          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_3)
        end
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
