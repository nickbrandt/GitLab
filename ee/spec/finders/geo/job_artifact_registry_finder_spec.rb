# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_artifacts_object_storage
  end

  let_it_be(:synced_group) { create(:group) }
  let_it_be(:nested_group_1) { create(:group, parent: synced_group) }
  let_it_be(:synced_project) { create(:project, group: synced_group) }
  let_it_be(:synced_project_in_nested_group) { create(:project, group: nested_group_1) }
  let_it_be(:unsynced_project) { create(:project) }
  let_it_be(:project_broken_storage) { create(:project, :broken_storage) }

  let!(:ci_job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
  let!(:ci_job_artifact_2) { create(:ci_job_artifact, project: synced_project_in_nested_group) }
  let!(:ci_job_artifact_3) { create(:ci_job_artifact, project: synced_project_in_nested_group) }
  let!(:ci_job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
  let!(:ci_job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
  let!(:ci_job_artifact_remote_1) { create(:ci_job_artifact, :remote_store) }
  let!(:ci_job_artifact_remote_2) { create(:ci_job_artifact, :remote_store) }
  let!(:ci_job_artifact_remote_3) { create(:ci_job_artifact, :remote_store) }

  subject { described_class.new(current_node_id: secondary.id) }

  describe '#count_syncable' do
    it 'counts registries for job artifacts' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      expect(subject.count_syncable).to eq 8
    end
  end

  describe '#count_registry' do
    it 'counts registries for job artifacts' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      expect(subject.count_registry).to eq 8
    end
  end

  describe '#count_synced' do
    it 'counts registries that has been synced' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      expect(subject.count_synced).to eq 3
    end
  end

  describe '#count_failed' do
    it 'counts registries that sync has failed' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      expect(subject.count_failed).to eq 3
    end
  end

  describe '#count_synced_missing_on_primary' do
    it 'counts registries that have been synced and are missing on the primary, excluding not synced ones' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      expect(subject.count_synced_missing_on_primary).to eq 3
    end
  end

  describe '#find_registry_differences' do
    # Untracked IDs should not contain any of these expired job artifacts.
    let!(:ci_job_artifact_6) { create(:ci_job_artifact, :expired, project: synced_project) }
    let!(:ci_job_artifact_7) { create(:ci_job_artifact, :expired, project: unsynced_project) }
    let!(:ci_job_artifact_8) { create(:ci_job_artifact, :expired, project: project_broken_storage) }
    let!(:ci_job_artifact_remote_4) { create(:ci_job_artifact, :expired, :remote_store) }

    context 'untracked IDs' do
      before do
        create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_1.id)
        create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_3.id)
        create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_4.id)
      end

      it 'includes job artifact IDs without an entry on the tracking database' do
        untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

        expect(untracked_ids).to match_array(
          [ci_job_artifact_2.id, ci_job_artifact_5.id, ci_job_artifact_remote_1.id,
           ci_job_artifact_remote_2.id, ci_job_artifact_remote_3.id])
      end

      it 'excludes job artifacts outside the ID range' do
        untracked_ids, _ = subject.find_registry_differences(ci_job_artifact_3.id..ci_job_artifact_remote_2.id)

        expect(untracked_ids).to match_array(
          [ci_job_artifact_5.id, ci_job_artifact_remote_1.id,
           ci_job_artifact_remote_2.id])
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'excludes job artifact IDs that are not in selectively synced projects' do
          untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

          expect(untracked_ids).to match_array([ci_job_artifact_2.id])
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'excludes job artifact IDs that are not in selectively synced projects' do
          untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

          expect(untracked_ids).to match_array([ci_job_artifact_5.id])
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'excludes job artifacts in object storage' do
          untracked_ids, _ = subject.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

          expect(untracked_ids).to match_array([ci_job_artifact_2.id, ci_job_artifact_5.id])
        end
      end
    end

    context 'unused tracked IDs' do
      context 'with an orphaned registry' do
        let!(:orphaned) { create(:geo_job_artifact_registry, artifact_id: non_existing_record_id) }

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

      context 'with an expired registry' do
        let!(:expired) { create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_6.id) }

        it 'includes expired tracked IDs that exists in the model table' do
          range = ci_job_artifact_6.id..ci_job_artifact_6.id

          _, unused_tracked_ids = subject.find_registry_differences(range)

          expect(unused_tracked_ids).to match_array([ci_job_artifact_6.id])
        end

        it 'excludes IDs outside the ID range' do
          range = (ci_job_artifact_6.id + 1)..(ci_job_artifact_6.id + 10)

          _, unused_tracked_ids = subject.find_registry_differences(range)

          expect(unused_tracked_ids).to be_empty
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        context 'with a tracked job artifact' do
          let!(:registry_entry) { create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_1.id) }
          let(:range) { ci_job_artifact_1.id..ci_job_artifact_4.id }

          context 'excluded from selective sync' do
            it 'includes tracked job artifact IDs that exist but are not in a selectively synced project' do
              create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_4.id)

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([ci_job_artifact_4.id])
            end
          end

          context 'included in selective sync' do
            it 'excludes tracked job artifact IDs that are in selectively synced projects' do
              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end

            it 'includes expired tracked IDs that are in selectively synced projects' do
              create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_6.id)

              range = ci_job_artifact_6.id..ci_job_artifact_6.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([ci_job_artifact_6.id])
            end
          end
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        context 'with a tracked job artifact' do
          let!(:registry_entry) { create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id) }
          let(:range) { ci_job_artifact_1.id..ci_job_artifact_5.id }

          context 'excluded from selective sync' do
            it 'includes tracked job artifact IDs that exist but are not in a selectively synced shard' do
              create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_1.id)

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([ci_job_artifact_1.id])
            end
          end

          context 'included in selective sync' do
            it 'excludes tracked job artifact IDs that are in selectively synced shards' do
              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end

            it 'includes expired tracked IDs that are in selectively synced shards' do
              create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_8.id)

              range = ci_job_artifact_8.id..ci_job_artifact_8.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([ci_job_artifact_8.id])
            end
          end
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        context 'with a tracked job artifact' do
          context 'in object storage' do
            it 'includes tracked job artifact IDs that are in object storage' do
              create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_1.id)
              range = ci_job_artifact_remote_1.id..ci_job_artifact_remote_1.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([ci_job_artifact_remote_1.id])
            end

            it 'includes expired tracked IDs that are in object storage' do
              create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_4.id)

              range = ci_job_artifact_remote_4.id..ci_job_artifact_remote_4.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([ci_job_artifact_remote_4.id])
            end
          end

          context 'not in object storage' do
            it 'excludes tracked job artifact IDs that are not in object storage' do
              create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_1.id)
              range = ci_job_artifact_1.id..ci_job_artifact_1.id

              _, unused_tracked_ids = subject.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end
    end
  end

  describe '#find_never_synced_registries' do
    it 'returns registries for job artifacts that have never been synced' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      registry_ci_job_artifact_3 = create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      registry_ci_job_artifact_remote_3 = create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      registries = subject.find_never_synced_registries(batch_size: 10)

      expect(registries).to match_ids(registry_ci_job_artifact_3, registry_ci_job_artifact_remote_3)
    end

    it 'excludes except_ids' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      registry_ci_job_artifact_remote_3 = create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      registries = subject.find_never_synced_registries(batch_size: 10, except_ids: [ci_job_artifact_3.id])

      expect(registries).to match_ids(registry_ci_job_artifact_remote_3)
    end
  end

  describe '#find_retryable_failed_registries' do
    it 'returns registries for job artifacts that have failed to sync' do
      registry_ci_job_artifact_1 = create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      registry_ci_job_artifact_4 = create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      registry_ci_job_artifact_remote_1 = create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      registries = subject.find_retryable_failed_registries(batch_size: 10)

      expect(registries).to match_ids(registry_ci_job_artifact_1, registry_ci_job_artifact_4, registry_ci_job_artifact_remote_1)
    end

    it 'excludes except_ids' do
      registry_ci_job_artifact_1 = create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      registry_ci_job_artifact_remote_1 = create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      registries = subject.find_retryable_failed_registries(batch_size: 10, except_ids: [ci_job_artifact_4.id])

      expect(registries).to match_ids(registry_ci_job_artifact_1, registry_ci_job_artifact_remote_1)
    end
  end

  describe '#find_retryable_synced_missing_on_primary_registries' do
    it 'returns registries for job artifacts that have been synced and are missing on the primary' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      registry_ci_job_artifact_2 = create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      registry_ci_job_artifact_5 = create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10)

      expect(registries).to match_ids(registry_ci_job_artifact_2, registry_ci_job_artifact_5)
    end

    it 'excludes except_ids' do
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_1.id)
      registry_ci_job_artifact_2 = create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_3.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_4.id)
      create(:geo_job_artifact_registry, artifact_id: ci_job_artifact_5.id, missing_on_primary: true, retry_at: 1.day.ago)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_1.id)
      create(:geo_job_artifact_registry, :failed, artifact_id: ci_job_artifact_remote_2.id, missing_on_primary: true)
      create(:geo_job_artifact_registry, :never_synced, artifact_id: ci_job_artifact_remote_3.id)

      registries = subject.find_retryable_synced_missing_on_primary_registries(batch_size: 10, except_ids: [ci_job_artifact_5.id])

      expect(registries).to match_ids(registry_ci_job_artifact_2)
    end
  end

  it_behaves_like 'a file registry finder'
end
