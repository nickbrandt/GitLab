# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::LfsObjectRegistryFinder, :geo do
  let_it_be(:secondary) { create(:geo_node) }

  before do
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

  subject { described_class.new(current_node_id: secondary.id) }

  describe '#count_syncable' do
    it 'counts registries for LFS objects' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      expect(subject.count_syncable).to eq 8
    end
  end

  describe '#count_registry' do
    it 'counts registries for LFS objects' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      expect(subject.count_registry).to eq 8
    end
  end

  describe '#count_synced' do
    it 'counts registries that has been synced' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      expect(subject.count_synced).to eq 3
    end
  end

  describe '#count_failed' do
    it 'counts registries that sync has failed' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      expect(subject.count_failed).to eq 3
    end
  end

  describe '#count_synced_missing_on_primary' do
    it 'counts registries that have been synced and are missing on the primary, excluding not synced ones' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      expect(subject.count_synced_missing_on_primary).to eq 3
    end
  end

  describe '#find_registry_differences' do
    let_it_be(:synced_group) { create(:group) }
    let_it_be(:nested_group_1) { create(:group, parent: synced_group) }
    let_it_be(:synced_project) { create(:project, group: synced_group) }
    let_it_be(:synced_project_in_nested_group) { create(:project, group: nested_group_1) }
    let_it_be(:unsynced_project) { create(:project) }
    let_it_be(:project_broken_storage) { create(:project, :broken_storage) }

    context 'untracked IDs' do
      before do
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_1.id)
        create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_3.id)
        create(:geo_lfs_object_registry, lfs_object_id: lfs_object_4.id)

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
        let!(:orphaned) { create(:geo_lfs_object_registry, lfs_object_id: non_existing_record_id) }

        it 'includes tracked IDs that do not exist in the model table' do
          range = non_existing_record_id..non_existing_record_id

          _, unused_tracked_ids = subject.find_registry_differences(range)

          expect(unused_tracked_ids).to match_array([non_existing_record_id])
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
    it 'returns registries for LFS objects that have never been synced' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      registry_lfs_object_3 = create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      registry_lfs_object_remote_3 = create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_never_synced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_lfs_object_3, registry_lfs_object_remote_3)
    end

    it 'excludes except_ids' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      registry_lfs_object_remote_3 = create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_unsynced(batch_size: 10, except_ids: [lfs_object_3.id])

      expect(registries).to match_ids(registry_lfs_object_remote_3)
    end
  end

  describe '#find_unsynced' do
    it 'returns registries for LFS objects that have never been synced' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      registry_lfs_object_3 = create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      registry_lfs_object_remote_3 = create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_unsynced(batch_size: 10)

      expect(registries).to match_ids(registry_lfs_object_3, registry_lfs_object_remote_3)
    end

    it 'excludes except_ids' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      registry_lfs_object_remote_3 = create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_unsynced(batch_size: 10, except_ids: [lfs_object_3.id])

      expect(registries).to match_ids(registry_lfs_object_remote_3)
    end
  end

  describe '#find_retryable_failed_registries' do
    it 'returns registries for LFS objects that have failed to sync' do
      registry_lfs_object_1 = create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      registry_lfs_object_4 = create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      registry_lfs_object_remote_1 = create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_retryable_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_4, registry_lfs_object_remote_1)
    end

    it 'excludes except_ids' do
      registry_lfs_object_1 = create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      registry_lfs_object_remote_1 = create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_retryable_failed_registries(batch_size: 10, except_ids: [lfs_object_4.id])

      expect(registries).to match_ids(registry_lfs_object_1, registry_lfs_object_remote_1)
    end
  end

  describe '#find_retryable_synced_missing_on_primary_registries' do
    it 'returns registries for LFS objects that have been synced and are missing on the primary' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      registry_lfs_object_2 = create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      registry_lfs_object_5 = create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

      expect(registries).to match_ids(registry_lfs_object_2, registry_lfs_object_5)
    end

    it 'excludes except_ids' do
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_1.id)
      registry_lfs_object_2 = create(:geo_lfs_object_registry, lfs_object_id: lfs_object_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_3.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_4.id)
      create(:geo_lfs_object_registry, lfs_object_id: lfs_object_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_1.id)
      create(:geo_lfs_object_registry, :failed, lfs_object_id: lfs_object_remote_2.id, missing_on_primary: true)
      create(:geo_lfs_object_registry, :never_synced, lfs_object_id: lfs_object_remote_3.id)

      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10, except_ids: [lfs_object_5.id])

      expect(registries).to match_ids(registry_lfs_object_2)
    end
  end

  it_behaves_like 'a file registry finder'
end
