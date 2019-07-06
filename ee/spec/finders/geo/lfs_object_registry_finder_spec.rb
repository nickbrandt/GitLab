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

  let!(:lfs_object_1) { create(:lfs_object) }
  let!(:lfs_object_2) { create(:lfs_object) }
  let!(:lfs_object_3) { create(:lfs_object) }
  let!(:lfs_object_4) { create(:lfs_object) }
  let!(:lfs_object_5) { create(:lfs_object) }
  let(:lfs_object_remote_1) { create(:lfs_object, :object_storage) }
  let(:lfs_object_remote_2) { create(:lfs_object, :object_storage) }
  let(:lfs_object_remote_3) { create(:lfs_object, :object_storage) }

  subject { described_class.new(current_node_id: secondary.id) }

  before do
    stub_current_geo_node(secondary)
    stub_lfs_object_storage
  end

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
        expect(subject.count_syncable).to eq 5
      end

      it 'ignores remote LFS objects' do
        lfs_object_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

        expect(subject.count_syncable).to eq 4
      end

      context 'with selective sync by namespace' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts LFS objects' do
          expect(subject.count_syncable).to eq 2
        end

        it 'ignores remote LFS objects' do
          lfs_object_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_syncable).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts LFS objects' do
          expect(subject.count_syncable).to eq 2
        end

        it 'ignores remote LFS objects' do
          lfs_object_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_syncable).to eq 1
        end
      end
    end

    describe '#count_registry' do
      it 'counts file registries for LFS objects' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)
        create(:geo_file_registry, :avatar)

        expect(subject.count_registry).to eq 3
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'does not apply the selective sync restriction' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)
          create(:geo_file_registry, :avatar)

          expect(subject.count_registry).to eq 3
        end
      end

      context 'with selective sync by shard' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_remote_1)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'does not apply the selective sync restriction' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_4.id)
          create(:geo_file_registry, :avatar)

          expect(subject.count_registry).to eq 3
        end
      end
    end

    describe '#count_synced' do
      it 'counts LFS objects that has been synced' do
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)

        expect(subject.count_synced).to eq 2
      end

      it 'ignores remote LFS objects' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)

        expect(subject.count_synced).to eq 2
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts LFS objects that has been synced' do
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)

          expect(subject.count_synced).to eq 1
        end

        it 'ignores remote LFS objects' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)
          lfs_object_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts LFS objects that has been synced' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_4.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_5.id)

          expect(subject.count_synced).to eq 1
        end

        it 'ignores remote LFS objects' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_3.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_4.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_5.id)
          lfs_object_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_synced).to eq 1
        end
      end
    end

    describe '#count_failed' do
      it 'counts LFS objects that sync has failed' do
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)

        expect(subject.count_failed).to eq 2
      end

      it 'ignores remote LFS objects' do
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_remote_1.id)
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_2.id)
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)

        expect(subject.count_failed).to eq 2
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts LFS objects that sync has failed' do
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)

          expect(subject.count_failed).to eq 1
        end

        it 'ignores remote LFS objects' do
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)
          lfs_object_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_failed).to eq 1
        end
      end

      context 'with selective sync by shard' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts LFS objects that sync has failed' do
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_4.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_5.id)

          expect(subject.count_failed).to eq 1
        end

        it 'ignores remote LFS objects' do
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_4.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_5.id)
          lfs_object_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_failed).to eq 1
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      it 'counts LFS objects that have been synced and are missing on the primary' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 1
      end

      it 'excludes LFS objects that are not missing on the primary' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_1.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 1
      end

      it 'excludes LFS objects that are not synced' do
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id, missing_on_primary: true)
        create(:geo_file_registry, :lfs, file_id: lfs_object_2.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 1
      end

      it 'ignores remote LFS objects' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 0
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts LFS objects that has been synced' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, missing_on_primary: true)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id, missing_on_primary: true)
          create(:geo_file_registry, :lfs, file_id: lfs_object_3.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 2
        end

        it 'ignores remote LFS objects' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id, missing_on_primary: true)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end
    end
  end

  context 'finds all the things' do
    describe '#find_unsynced' do
      it 'returns LFS objects without an entry on the tracking database' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_1.id)
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)

        lfs_objects = subject.find_unsynced(batch_size: 10)

        expect(lfs_objects).to match_ids(lfs_object_2, lfs_object_4, lfs_object_5)
      end

      it 'excludes LFS objects without an entry on the tracking database' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_1.id)
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)

        lfs_objects = subject.find_unsynced(batch_size: 10, except_file_ids: [lfs_object_2.id])

        expect(lfs_objects).to match_ids(lfs_object_4, lfs_object_5)
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_4)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'returns LFS objects without an entry on the tracking database' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)

          lfs_objects = subject.find_unsynced(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_1, lfs_object_3)
        end

        it 'ignores remote LFS objects' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id)
          lfs_object_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          lfs_objects = subject.find_unsynced(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_3)
        end
      end

      context 'with selective sync by shard' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_5)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'counts LFS objects that sync has failed' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_4.id)

          lfs_objects = subject.find_unsynced(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_5)
        end

        it 'ignores remote LFS objects' do
          lfs_object_5.update_column(:file_store, ObjectStorage::Store::REMOTE)

          lfs_objects = subject.find_unsynced(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_4)
        end
      end
    end

    describe '#find_migrated_local' do
      it 'returns LFS objects remotely and successfully synced locally' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id)

        lfs_objects = subject.find_migrated_local(batch_size: 10)

        expect(lfs_objects).to match_ids(lfs_object_remote_1)
      end

      it 'excludes LFS objects stored remotely, but not synced yet' do
        create(:lfs_object, :object_storage)

        lfs_objects = subject.find_migrated_local(batch_size: 10)

        expect(lfs_objects).to be_empty
      end

      it 'excludes synced LFS objects that are stored locally' do
        create(:geo_file_registry, :avatar, file_id: lfs_object_1.id)

        lfs_objects = subject.find_migrated_local(batch_size: 10)

        expect(lfs_objects).to be_empty
      end

      it 'excludes except_file_ids' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object_remote_2.id)

        lfs_objects = subject.find_migrated_local(batch_size: 10, except_file_ids: [lfs_object_remote_1.id])

        expect(lfs_objects).to match_ids(lfs_object_remote_2)
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_remote_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_remote_2)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_remote_3)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'returns LFS objects remotely and successfully synced locally' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_remote_2.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_remote_3.id)

          lfs_objects = subject.find_migrated_local(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_remote_2)
        end
      end

      context 'with selective sync by shard' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_remote_1)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_remote_2)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_remote_3)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'returns LFS objects remotely and successfully synced locally' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_remote_1.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object_remote_2.id)

          lfs_objects = subject.find_migrated_local(batch_size: 10)

          expect(lfs_objects).to match_ids(lfs_object_remote_2)
        end
      end
    end

    describe '#find_retryable_failed_registries' do
      it 'returns registries for LFS objects that have failed to sync' do
        create(:geo_file_registry, :lfs, file_id: lfs_object_1.id)
        registry_lfs_object_2 = create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_2.id)
        registry_lfs_object_3 = create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id)
        create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_4.id, retry_at: 1.day.from_now)

        registries = subject.find_retryable_failed_registries(batch_size: 10)

        expect(registries).to match_ids(registry_lfs_object_2, registry_lfs_object_3)
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_4)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'returns registries for LFS objects that have failed to sync' do
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
          registry_lfs_object_2 = create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id, retry_at: 1.day.from_now)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_4.id)

          registries = subject.find_retryable_failed_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_2)
        end
      end

      context 'with selective sync by shard' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'returns registries for LFS objects that have failed to sync' do
          registry_lfs_object_1 = create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_1.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_2.id)
          create(:geo_file_registry, :lfs, :failed, file_id: lfs_object_3.id, retry_at: 1.day.from_now)
          create(:geo_file_registry, :lfs, file_id: lfs_object_4.id)

          registries = subject.find_retryable_failed_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_1)
        end
      end
    end

    describe '#find_retryable_synced_missing_on_primary_registries' do
      it 'returns registries for LFS objects that have been synced and are missing on the primary' do
        registry_lfs_object_1 = create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, missing_on_primary: true, retry_at: nil)
        registry_lfs_object_2 = create(:geo_file_registry, :lfs, file_id: lfs_object_2.id, missing_on_primary: true, retry_at: 1.day.ago)
        create(:geo_file_registry, :lfs, file_id: lfs_object_3.id, missing_on_primary: true, retry_at: 1.day.from_now)
        create(:geo_file_registry, :lfs, file_id: lfs_object_4.id, missing_on_primary: false)

        registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

        expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_2)
      end

      context 'with selective sync by namespace' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_3)
          create(:lfs_objects_project, project: project_broken_storage, lfs_object: lfs_object_4)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
        end

        it 'returns registries for LFS objects that have been synced and are missing on the primary' do
          create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, missing_on_primary: true, retry_at: nil)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id, missing_on_primary: false)
          registry_lfs_object_3 = create(:geo_file_registry, :lfs, file_id: lfs_object_3.id, missing_on_primary: true, retry_at: 1.day.ago)
          registry_lfs_object_4 = create(:geo_file_registry, :lfs, file_id: lfs_object_4.id, missing_on_primary: true, retry_at: nil)

          registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_3, registry_lfs_object_4)
        end
      end

      context 'with selective sync by shard' do
        before do
          allow_any_instance_of(LfsObjectsProject).to receive(:update_project_statistics).and_return(nil)

          create(:lfs_objects_project, project: synced_project, lfs_object: lfs_object_1)
          create(:lfs_objects_project, project: synced_project_in_nested_group, lfs_object: lfs_object_2)
          create(:lfs_objects_project, project: unsynced_project, lfs_object: lfs_object_3)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'returns registries for LFS objects that have been synced and are missing on the primary' do
          registry_lfs_object_1 = create(:geo_file_registry, :lfs, file_id: lfs_object_1.id, missing_on_primary: true, retry_at: nil)
          create(:geo_file_registry, :lfs, file_id: lfs_object_2.id, missing_on_primary: true, retry_at: 1.day.from_now)
          create(:geo_file_registry, :lfs, file_id: lfs_object_3.id, missing_on_primary: true, retry_at: 1.day.ago)
          create(:geo_file_registry, :lfs, file_id: lfs_object_4.id, missing_on_primary: false)

          registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

          expect(registries).to match_ids(registry_lfs_object_1)
        end
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
