# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactRegistryFinder, :geo_fdw do
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

  let!(:job_artifact_synced_project) { create(:ci_job_artifact, project: synced_project) }
  let!(:job_artifact_unsynced_project) { create(:ci_job_artifact, project: unsynced_project) }
  let!(:job_artifact_broken_storage_1) { create(:ci_job_artifact, project: project_broken_storage) }
  let!(:job_artifact_broken_storage_2) { create(:ci_job_artifact, project: project_broken_storage) }
  let!(:job_artifact_expired_synced_project) { create(:ci_job_artifact, :expired, project: synced_project) }
  let!(:job_artifact_expired_broken_storage) { create(:ci_job_artifact, :expired, project: project_broken_storage) }
  let!(:job_artifact_remote_synced_project) { create(:ci_job_artifact, :remote_store, project: synced_project) }
  let!(:job_artifact_remote_unsynced_project) { create(:ci_job_artifact, :remote_store, project: unsynced_project) }
  let!(:job_artifact_remote_broken_storage) { create(:ci_job_artifact, :expired, :remote_store, project: project_broken_storage) }

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
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts non-expired job artifacts' do
          expect(subject.count_syncable).to eq 4
        end
      end
    end

    describe '#count_synced' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_unsynced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_2.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_synced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id)
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
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts job artifacts that has been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 2
        end
      end
    end

    describe '#count_failed' do
      before do
        create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_synced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_unsynced_project.id)
        create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_broken_storage_1.id)
        create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_expired_synced_project.id)
        create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_expired_broken_storage.id)
        create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_remote_synced_project.id)
        create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_remote_broken_storage.id)
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
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 2
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false, missing_on_primary: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_unsynced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_synced_project.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_unsynced_project.id, missing_on_primary: false)
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
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end
    end

    describe '#count_registry' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_unsynced_project.id)
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
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts file registries for job artifacts ignoring remote artifacts' do
          expect(subject.count_registry).to eq 4
        end
      end
    end
  end

  context 'finds all the things' do
    describe '#find_registry_differences' do
      context 'untracked IDs' do
        before do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id)
          create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_broken_storage_1.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_unsynced_project.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id)
        end

        it 'includes Job Artifact IDs without an entry on the tracking database' do
          untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

          expect(untracked_ids).to match_array(
            [job_artifact_unsynced_project.id, job_artifact_remote_synced_project.id,
             job_artifact_broken_storage_2.id, job_artifact_expired_synced_project.id,
             job_artifact_remote_broken_storage.id])
        end

        it 'excludes Job Artifacts outside the ID range' do
          untracked_ids, _ = subject.find_registry_differences(job_artifact_unsynced_project.id..job_artifact_broken_storage_2.id)

          expect(untracked_ids).to match_array(
            [job_artifact_unsynced_project.id, job_artifact_broken_storage_2.id])
        end

        context 'with selective sync by namespace' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

          it 'excludes Job Artifacts that are not in selectively synced projects' do
            untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

            expect(untracked_ids).to match_array([job_artifact_expired_synced_project.id, job_artifact_remote_synced_project.id])
          end
        end

        context 'with selective sync by shard' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

          it 'excludes Job Artifacts that are not in selectively synced projects' do
            untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

            expect(untracked_ids).to match_array([job_artifact_broken_storage_2.id, job_artifact_remote_broken_storage.id])
          end
        end

        context 'with object storage sync disabled' do
          let(:secondary) { create(:geo_node, :local_storage_only) }

          it 'excludes Job Artifacts in object storage' do
            untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

            expect(untracked_ids).to match_array(
              [job_artifact_unsynced_project.id, job_artifact_broken_storage_2.id,
               job_artifact_expired_synced_project.id])
          end
        end
      end

      context 'unused tracked IDs' do
        context 'with an orphaned registry' do
          let!(:orphaned) { create(:geo_job_artifact_registry, artifact_id: non_existing_record_id) }

          it 'includes tracked IDs that do not exist in the model table' do
            _, unused_tracked_ids = subject.find_registry_differences(non_existing_record_id..non_existing_record_id)

            expect(unused_tracked_ids).to match_array([non_existing_record_id])
          end

          it 'excludes IDs outside the ID range' do
            _, unused_tracked_ids = subject.find_registry_differences(1..1000)

            expect(unused_tracked_ids).to be_empty
          end
        end

        context 'with selective sync by namespace' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

          context 'with a tracked Job Artifact' do
            it 'includes tracked Job Artifact IDs that exist but are not in a selectively synced project' do
              create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id)
              create(:geo_job_artifact_registry, artifact_id: job_artifact_unsynced_project.id)

              _, unused_tracked_ids = subject.find_registry_differences(job_artifact_synced_project.id..job_artifact_unsynced_project.id)

              expect(unused_tracked_ids).to match_array([job_artifact_unsynced_project.id])
            end
          end

          context 'without a tracked Job Artifact' do
            it 'returns empty' do
              _, unused_tracked_ids = subject.find_registry_differences(job_artifact_synced_project.id..job_artifact_unsynced_project.id)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end

        context 'with selective sync by shard' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

          context 'with a tracked Job Artifact' do
            it 'includes tracked Job Artifact IDs that exist but are not in a selectively synced project' do
              create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id)
              create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id)

              _, unused_tracked_ids = subject.find_registry_differences(job_artifact_synced_project.id..job_artifact_broken_storage_1.id)

              expect(unused_tracked_ids).to match_array([job_artifact_synced_project.id])
            end
          end

          context 'without a tracked Job Artifact' do
            it 'returns empty' do
              _, unused_tracked_ids = subject.find_registry_differences(job_artifact_synced_project.id..job_artifact_broken_storage_1.id)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end

        context 'with object storage sync disabled' do
          let(:secondary) { create(:geo_node, :local_storage_only) }

          context 'with a tracked Job Artifact' do
            context 'in object storage' do
              it 'includes tracked Job Artifact IDs that are in object storage' do
                create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id)
                range = job_artifact_remote_synced_project.id..job_artifact_remote_synced_project.id

                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to match_array([job_artifact_remote_synced_project.id])
              end
            end

            context 'not in object storage' do
              it 'excludes tracked Job Artifact IDs that are not in object storage' do
                create(:geo_lfs_object_registry, lfs_object_id: job_artifact_synced_project.id)
                range = job_artifact_synced_project.id..job_artifact_synced_project.id

                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to be_empty
              end
            end
          end
        end
      end
    end

    describe '#find_never_synced_registries' do
      let!(:registry_job_artifact_1) { create(:geo_job_artifact_registry, :never_synced, artifact_id: job_artifact_synced_project.id) }
      let!(:registry_job_artifact_2) { create(:geo_job_artifact_registry, :never_synced, artifact_id: job_artifact_unsynced_project.id) }
      let!(:registry_job_artifact_3) { create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id) }
      let!(:registry_job_artifact_4) { create(:geo_job_artifact_registry, :failed, artifact_id: job_artifact_broken_storage_2.id) }
      let!(:registry_job_artifact_remote_1) { create(:geo_job_artifact_registry, :never_synced, artifact_id: job_artifact_remote_synced_project.id) }

      it 'returns registries for Job Artifacts that have never been synced' do
        registries = subject.find_never_synced_registries(batch_size: 10)

        expect(registries).to match_ids(registry_job_artifact_1, registry_job_artifact_2, registry_job_artifact_remote_1)
      end
    end

    describe '#find_unsynced' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id, success: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id, success: true)
      end

      context 'without selective sync' do
        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10, except_ids: [job_artifact_unsynced_project.id])

          expect(job_artifacts).to match_ids(job_artifact_remote_synced_project, job_artifact_remote_unsynced_project,
                                             job_artifact_broken_storage_2)
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_synced_project)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_broken_storage_2)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones and remotes' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_unsynced_project, job_artifact_broken_storage_2)
        end
      end
    end

    describe '#find_migrated_local' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_unsynced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_broken_storage.id)
      end

      it 'returns job artifacts excluding ones from the exception list' do
        job_artifacts = subject.find_migrated_local(batch_size: 10, except_ids: [job_artifact_remote_synced_project.id])

        expect(job_artifacts).to match_ids(job_artifact_remote_unsynced_project, job_artifact_remote_broken_storage)
      end

      it 'includes synced job artifacts that are expired, exclude stored locally' do
        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_remote_synced_project, job_artifact_remote_unsynced_project,
                                           job_artifact_remote_broken_storage)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns job artifacts remotely and successfully synced locally' do
          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_synced_project)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns job artifacts remotely and successfully synced locally' do
          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_broken_storage)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'returns job artifacts excluding ones from the exception list' do
          job_artifacts = subject.find_migrated_local(batch_size: 10, except_ids: [job_artifact_remote_synced_project.id])

          expect(job_artifacts).to match_ids(job_artifact_remote_unsynced_project, job_artifact_remote_broken_storage)
        end
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
