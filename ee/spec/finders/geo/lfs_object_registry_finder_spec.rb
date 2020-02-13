# frozen_string_literal: true

require 'spec_helper'

describe Geo::LfsObjectRegistryFinder, :geo_fdw do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction of a
  # different connection.
  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let(:nested_group_1) { create(:group, parent: synced_group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:synced_project_in_nested_group) { create(:project, group: nested_group_1) }
  let(:unsynced_project) { create(:project) }
  let(:project_broken_storage) { create(:project, :broken_storage) }

  subject { described_class.new(current_node_id: secondary.id) }

  before do
    stub_current_geo_node(secondary)
    stub_lfs_object_storage
  end

  let!(:lfs_object_1) { create(:lfs_object) }
  let!(:lfs_object_2) { create(:lfs_object) }
  let!(:lfs_object_3) { create(:lfs_object) }
  let!(:lfs_object_4) { create(:lfs_object) }
  let!(:lfs_object_5) { create(:lfs_object) }
  let!(:lfs_object_remote_1) { create(:lfs_object, :object_storage) }
  let!(:lfs_object_remote_2) { create(:lfs_object, :object_storage) }
  let!(:lfs_object_remote_3) { create(:lfs_object, :object_storage) }

  context 'counts all the things' do
    describe '#count_syncable' do
      before do
        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)
      end

      it 'counts LFS objects' do
        expect(subject.count_syncable).to eq 8
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts LFS objects' do
          expect(subject.count_syncable).to eq 2
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts LFS objects' do
          expect(subject.count_syncable).to eq 2
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts LFS objects ignoring remote objects' do
          expect(subject.count_syncable).to eq 5
        end
      end
    end

    describe '#count_registry' do
      before do
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_3.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_4.id)
        create(:geo_upload_registry, :avatar)

        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_remote_1)
      end

      it 'counts registries for LFS objects' do
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

        it 'counts registries for LFS objects' do
          expect(subject.count_registry).to eq 4
        end
      end
    end

    describe '#count_synced' do
      before do
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_3.id)
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id)

        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)
      end

      it 'counts LFS objects that has been synced' do
        expect(subject.count_synced).to eq 4
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)
        end

        it 'counts LFS objects that has been synced' do
          expect(subject.count_synced).to eq 1
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts LFS objects that has been synced' do
          expect(subject.count_synced).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts LFS objects that has been synced ignoring remote objects' do
          expect(subject.count_synced).to eq 3
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts LFS objects that has been synced, ignoring remotes' do
          expect(subject.count_synced).to eq 3
        end
      end
    end

    describe '#count_failed' do
      before do
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id)
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_3.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_4.id)
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_5.id)
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)

        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)
      end

      it 'counts LFS objects that sync has failed' do
        expect(subject.count_failed).to eq 4
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts LFS objects that sync has failed' do
          expect(subject.count_failed).to eq 1
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts LFS objects that sync has failed' do
          expect(subject.count_failed).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts LFS objects that sync has failed, ignoring remotes' do
          expect(subject.count_failed).to eq 3
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      before do
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_3.id, missing_on_primary: true)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id, missing_on_primary: true)

        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
      end

      it 'counts LFS objects that have been synced and are missing on the primary, excluding not synced ones' do
        expect(subject.count_synced_missing_on_primary).to eq 2
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts LFS objects that has been synced' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts LFS objects that have been synced and are missing on the primary, excluding not synced ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end
    end
  end

  context 'finds all the things' do
    describe '#find_registry_differences' do
      context 'untracked IDs' do
        before do
          create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id)
          create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_3.id)
          create(:geo_lfs_object_registry, lfs_object_id: lfs_object_4.id)

          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_4)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)
        end

        it 'includes LFS object IDs without an entry on the tracking database' do
          untracked_ids, _ = subject.find_registry_differences(LfsObject.first.id..LfsObject.last.id)

          expect(untracked_ids).to match_array(
            [lfs_object_2.id, lfs_object_5.id, lfs_object_remote_1.id,
             lfs_object_remote_2.id, lfs_object_remote_3.id])
        end

        it 'excludes LFS objects outside the ID range' do
          untracked_ids, _ = subject.find_registry_differences(lfs_object_3.id..lfs_object_remote_2.id)

          expect(untracked_ids).to match_array(
            [lfs_object_5.id, lfs_object_remote_1.id,
             lfs_object_remote_2.id])
        end

        context 'with selective sync by namespace' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

          it 'excludes LFS object IDs that are not in selectively synced projects' do
            untracked_ids, _ = subject.find_registry_differences(LfsObject.first.id..LfsObject.last.id)

            expect(untracked_ids).to match_array([lfs_object_2.id])
          end
        end

        context 'with selective sync by shard' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

          it 'excludes LFS object IDs that are not in selectively synced projects' do
            untracked_ids, _ = subject.find_registry_differences(LfsObject.first.id..LfsObject.last.id)

            expect(untracked_ids).to match_array([lfs_object_5.id])
          end
        end

        context 'with object storage sync disabled' do
          let(:secondary) { create(:geo_node, :local_storage_only) }

          it 'excludes LFS objects in object storage' do
            untracked_ids, _ = subject.find_registry_differences(LfsObject.first.id..LfsObject.last.id)

            expect(untracked_ids).to match_array([lfs_object_2.id, lfs_object_5.id])
          end
        end
      end

      context 'unused tracked IDs' do
        context 'with an orphaned registry' do
          let!(:orphaned) { create(:geo_lfs_object_registry, lfs_object_id: 1234567) }

          it 'includes tracked IDs that do not exist in the model table' do
            range = 1234567..1234567

            _, unused_tracked_ids = subject.find_registry_differences(range)

            expect(unused_tracked_ids).to match_array([1234567])
          end

          it 'excludes IDs outside the ID range' do
            range = 1..1000

            _, unused_tracked_ids = subject.find_registry_differences(range)

            expect(unused_tracked_ids).to be_empty
          end
        end

        context 'with selective sync by namespace' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

          context 'with a tracked LFS object' do
            let!(:registry_entry) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id) }
            let(:range) { lfs_object_1.id..lfs_object_1.id }

            context 'excluded from selective sync' do
              it 'includes tracked LFS object IDs that exist but are not in a selectively synced project' do
                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to match_array([lfs_object_1.id])
              end
            end

            context 'included in selective sync' do
              let!(:join_record) { create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1) }

              it 'excludes tracked LFS object IDs that are in selectively synced projects' do
                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to be_empty
              end
            end
          end
        end

        context 'with selective sync by shard' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

          context 'with a tracked LFS object' do
            let!(:registry_entry) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id) }
            let(:range) { lfs_object_1.id..lfs_object_1.id }

            context 'excluded from selective sync' do
              it 'includes tracked LFS object IDs that exist but are not in a selectively synced project' do
                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to match_array([lfs_object_1.id])
              end
            end

            context 'included in selective sync' do
              let!(:join_record) { create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_1) }

              it 'excludes tracked LFS object IDs that are in selectively synced projects' do
                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to be_empty
              end
            end
          end
        end

        context 'with object storage sync disabled' do
          let(:secondary) { create(:geo_node, :local_storage_only) }

          context 'with a tracked LFS object' do
            context 'in object storage' do
              it 'includes tracked LFS object IDs that are in object storage' do
                create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id)
                range = lfs_object_remote_1.id..lfs_object_remote_1.id

                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to match_array([lfs_object_remote_1.id])
              end
            end

            context 'not in object storage' do
              it 'excludes tracked LFS object IDs that are not in object storage' do
                create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id)
                range = lfs_object_1.id..lfs_object_1.id

                _, unused_tracked_ids = subject.find_registry_differences(range)

                expect(unused_tracked_ids).to be_empty
              end
            end
          end
        end
      end
    end

    describe '#find_never_synced_registries' do
      let!(:registry_lfs_object_1) { create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_1.id) }
      let!(:registry_lfs_object_2) { create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_2.id) }
      let!(:registry_lfs_object_3) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_3.id) }
      let!(:registry_lfs_object_4) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id) }
      let!(:registry_lfs_object_remote_1) { create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_1.id) }

      it 'returns registries for LFS objects that have never been synced' do
        registries = subject.find_never_synced_registries(batch_size: 10)

        expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_2, registry_lfs_object_remote_1)
      end
    end

    describe '#find_unsynced' do
      before do
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id)
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_3.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_4.id)

        allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

        create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
        create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
        create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_3)
        create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_4)
        create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)
      end

      it 'returns LFS objects without an entry on the tracking database' do
        lfs_objects = subject.find_unsynced(batch_size: 10)

        expect(lfs_objects).to match_ids(lfs_object_2, lfs_object_5,
                                         lfs_object_remote_1, lfs_object_remote_2, lfs_object_remote_3)
      end

      it 'excludes LFS objects without an entry on the tracking database' do
        lfs_objects = subject.find_unsynced(batch_size: 10, except_ids: [lfs_object_2.id])

        expect(lfs_objects).to match_ids(lfs_object_5, lfs_object_remote_1,
                                         lfs_object_remote_2, lfs_object_remote_3)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns LFS objects without an entry on the tracking database' do
          lfs_objects = subject.find_unsynced(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_2)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts LFS objects that sync has failed' do
          lfs_objects = subject.find_unsynced(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_5)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'returns LFS objects without an entry on the tracking database' do
          lfs_objects = subject.find_unsynced(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_2, lfs_object_5)
        end
      end
    end

    describe '#find_migrated_local' do
      it 'returns LFS objects remotely and successfully synced locally' do
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id)

        lfs_objects = subject.find_migrated_local(batch_size: 10)

        expect(lfs_objects).to match_ids(lfs_object_remote_1)
      end

      it 'excludes LFS objects stored remotely, but not synced yet' do
        create(:lfs_object, :object_storage)

        lfs_objects = subject.find_migrated_local(batch_size: 10)

        expect(lfs_objects).to be_empty
      end

      it 'excludes synced LFS objects that are stored locally' do
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id)

        lfs_objects = subject.find_migrated_local(batch_size: 10)

        expect(lfs_objects).to be_empty
      end

      it 'excludes except_ids' do
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id)

        lfs_objects = subject.find_migrated_local(batch_size: 10, except_ids: [lfs_object_remote_1.id])

        expect(lfs_objects).to match_ids(lfs_object_remote_2)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_remote_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_remote_2)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_remote_3)
        end

        it 'returns LFS objects remotely and successfully synced locally' do
          create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id)
          create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_3.id)

          lfs_objects = subject.find_migrated_local(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_remote_2)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_remote_1)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_remote_2)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_remote_3)
        end

        it 'returns LFS objects remotely and successfully synced locally' do
          create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id)
          create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id)

          lfs_objects = subject.find_migrated_local(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_remote_2)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'returns LFS objects remotely and successfully synced locally' do
          create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_1.id)

          lfs_objects = subject.find_migrated_local(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_remote_1)
        end
      end
    end

    describe '#find_retryable_failed_registries' do
      let!(:registry_lfs_object_1) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id) }
      let!(:registry_lfs_object_2) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_2.id) }
      let!(:registry_lfs_object_3) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_3.id, retry_at: 1.day.from_now) }
      let!(:registry_lfs_object_4) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id, retry_at: 1.day.from_now) }
      let!(:registry_lfs_object_remote_1) { create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id) }

      it 'returns registries for LFS objects that have failed to sync' do
        registries = subject.find_retryable_failed_registries(batch_size: 10)

        expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_2, registry_lfs_object_remote_1)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_4)
        end

        it 'returns registries for LFS objects that have failed to sync' do
          registries = subject.find_retryable_failed_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_2)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
        end

        it 'returns registries for LFS objects that have failed to sync' do
          registries = subject.find_retryable_failed_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_1)
        end
      end
    end

    describe '#find_retryable_synced_missing_on_primary_registries' do
      let!(:registry_lfs_object_1) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id, missing_on_primary: true, retry_at: nil) }
      let!(:registry_lfs_object_2) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true, retry_at: 1.day.from_now) }
      let!(:registry_lfs_object_3) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_3.id, missing_on_primary: true, retry_at: 1.day.ago) }
      let!(:registry_lfs_object_4) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_4.id, missing_on_primary: true, retry_at: nil) }
      let!(:registry_lfs_object_5) { create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: false) }

      it 'returns registries for LFS objects that have been synced and are missing on the primary' do
        registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

        expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_3, registry_lfs_object_4)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
        end

        it 'returns registries for LFS objects that have been synced and are missing on the primary' do
          registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_1)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
        end

        it 'returns registries for LFS objects that have been synced and are missing on the primary' do
          registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_3, registry_lfs_object_4)
        end
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
