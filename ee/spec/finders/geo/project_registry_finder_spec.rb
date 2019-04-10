require 'spec_helper'

describe Geo::ProjectRegistryFinder, :geo do
  using RSpec::Parameterized::TableSyntax

  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction of a
  # different connection.
  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let(:nested_group_1) { create(:group, parent: synced_group) }
  let(:project) { create(:project) }
  let(:project_1_in_synced_group) { create(:project, group: synced_group) }
  let(:project_2_in_synced_group) { create(:project, group: nested_group_1) }
  let(:project_3_in_synced_group) { create(:project, group: synced_group) }
  let(:project_4_broken_storage) { create(:project, :broken_storage) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'counts all the things' do |method_prefix|
    describe '#count_synced_repositories' do
      before do
        create(:geo_project_registry, :synced, project: project)
        create(:geo_project_registry, :synced, :repository_dirty, project: project_1_in_synced_group)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_2_in_synced_group)
        create(:geo_project_registry, :sync_failed, project: project_3_in_synced_group)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_4_broken_storage)
      end

      it 'counts registries that repository have been synced' do
        expect(subject.count_synced_repositories).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that repository have been synced where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_synced_repositories).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that repository have been synced where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_synced_repositories).to eq 1
        end
      end
    end

    describe '#count_synced_wikis' do
      before do
        create(:geo_project_registry, :synced, project: project)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_1_in_synced_group)
        create(:geo_project_registry, :synced, :repository_dirty, project: project_2_in_synced_group)
        create(:geo_project_registry, :sync_failed, project: project_3_in_synced_group)
        create(:geo_project_registry, :synced, :repository_dirty, project: project_4_broken_storage)
      end

      it 'counts registries that wiki have been synced' do
        expect(subject.count_synced_wikis).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that wiki have been synced where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_synced_wikis).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that wiki have been synced where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_synced_wikis).to eq 1
        end
      end
    end

    describe '#count_failed_repositories' do
      before do
        create(:geo_project_registry, :synced, project: project)
        create(:geo_project_registry, :repository_sync_failed, project: project_1_in_synced_group)
        create(:geo_project_registry, :wiki_sync_failed, project: project_2_in_synced_group)
        create(:geo_project_registry, :sync_failed, project: project_3_in_synced_group)
        create(:geo_project_registry, :repository_sync_failed, project: project_4_broken_storage)
      end

      it 'counts registries that repository sync has failed' do
        expect(subject.count_failed_repositories).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that repository sync has failed where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_failed_repositories).to eq 2
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that repository sync has failed where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_failed_repositories).to eq 1
        end
      end
    end

    describe '#count_failed_wikis' do
      before do
        create(:geo_project_registry, :synced, project: project)
        create(:geo_project_registry, :wiki_sync_failed, project: project_1_in_synced_group)
        create(:geo_project_registry, :repository_sync_failed, project: project_2_in_synced_group)
        create(:geo_project_registry, :sync_failed, project: project_3_in_synced_group)
        create(:geo_project_registry, :wiki_sync_failed, project: project_4_broken_storage)
      end

      it 'counts registries that wiki sync has failed' do
        expect(subject.count_failed_wikis).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that wiki sync has failed where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_failed_wikis).to eq 2
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that wiki sync has failed where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_failed_wikis).to eq 1
        end
      end
    end

    describe '#count_verified_repositories' do
      before do
        create(:geo_project_registry, :repository_verified, :wiki_verified, project: project)
        create(:geo_project_registry, :repository_verified, project: project_1_in_synced_group)
        create(:geo_project_registry, :repository_verification_failed, project: project_3_in_synced_group)
        create(:geo_project_registry, :repository_verified, project: project_4_broken_storage)
        create(:geo_project_registry, :wiki_verified, project: project_2_in_synced_group)
      end

      it 'counts registries that repository have beend verified' do
        expect(subject.count_verified_repositories).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that repository have beend verified where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_verified_repositories).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that repository have beend verified where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_verified_repositories).to eq 1
        end
      end
    end

    describe '#count_verified_wikis' do
      before do
        create(:geo_project_registry, :wiki_verified, :wiki_verified, project: project)
        create(:geo_project_registry, :wiki_verified, project: project_1_in_synced_group)
        create(:geo_project_registry, :wiki_verification_failed, project: project_3_in_synced_group)
        create(:geo_project_registry, :wiki_verified, project: project_4_broken_storage)
        create(:geo_project_registry, :repository_verified, project: project_2_in_synced_group)
      end

      it 'counts registries that wiki have beend verified' do
        expect(subject.count_verified_wikis).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that wiki have beend verified where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_verified_wikis).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that wiki have beend verified where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_verified_wikis).to eq 1
        end
      end
    end

    describe '#count_verification_failed_repositories' do
      before do
        create(:geo_project_registry, :repository_verification_failed, :wiki_verification_failed, project: project)
        create(:geo_project_registry, :repository_verification_failed, project: project_1_in_synced_group)
        create(:geo_project_registry, :repository_verification_failed, project: project_4_broken_storage)
        create(:geo_project_registry, :wiki_verification_failed, project: project_2_in_synced_group)
      end

      it 'counts registries that repository verification has failed' do
        expect(subject.count_verification_failed_repositories).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that repository verification has failed where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_verification_failed_repositories).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that repository verification has failed where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_verification_failed_repositories).to eq 1
        end
      end
    end

    describe '#count_verification_failed_wikis' do
      before do
        create(:geo_project_registry, :repository_verification_failed, :wiki_verification_failed, project: project)
        create(:geo_project_registry, :wiki_verification_failed, project: project_1_in_synced_group)
        create(:geo_project_registry, :wiki_verification_failed, project: project_4_broken_storage)
        create(:geo_project_registry, :repository_verification_failed, project: project_2_in_synced_group)
      end

      it 'counts registries that wiki verification has failed' do
        expect(subject.count_verification_failed_wikis).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that wiki verification has failed where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_verification_failed_wikis).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that wiki verification has failed where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_verification_failed_wikis).to eq 1
        end
      end
    end

    describe '#count_repositories_retrying_verification' do
      before do
        create(:geo_project_registry, :repository_retrying_verification, :wiki_retrying_verification, project: project)
        create(:geo_project_registry, :repository_retrying_verification, project: project_1_in_synced_group)
        create(:geo_project_registry, :repository_retrying_verification, project: project_4_broken_storage)
        create(:geo_project_registry, :wiki_retrying_verification, project: project_2_in_synced_group)
      end

      it 'counts registries that repository retrying verification' do
        expect(subject.count_repositories_retrying_verification).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that repository retrying verification where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_repositories_retrying_verification).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that repository retrying verification where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_repositories_retrying_verification).to eq 1
        end
      end
    end

    describe '#count_wikis_retrying_verification' do
      before do
        create(:geo_project_registry, :repository_retrying_verification, :wiki_retrying_verification, project: project)
        create(:geo_project_registry, :repository_retrying_verification, project: project_1_in_synced_group)
        create(:geo_project_registry, :wiki_retrying_verification, project: project_2_in_synced_group)
        create(:geo_project_registry, :wiki_retrying_verification, project: project_4_broken_storage)
      end

      it 'counts registries that wiki retrying verification' do
        expect(subject.count_wikis_retrying_verification).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts registries that wiki retrying verification where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_wikis_retrying_verification).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts registries that wiki retrying verification where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_wikis_retrying_verification).to eq 1
        end
      end
    end

    describe '#count_repositories_checksum_mismatch' do
      before do
        create(:geo_project_registry, :repository_checksum_mismatch, :wiki_checksum_mismatch, project: project)
        create(:geo_project_registry, :repository_checksum_mismatch, project: project_1_in_synced_group)
        create(:geo_project_registry, :repository_checksum_mismatch, :wiki_verified, project: project_4_broken_storage)
        create(:geo_project_registry, :wiki_checksum_mismatch, project: project_2_in_synced_group)
      end

      it 'counts registries that repository mismatch' do
        expect(subject.count_repositories_checksum_mismatch).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts mismatch registries where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_repositories_checksum_mismatch).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts mismatch registries where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_repositories_checksum_mismatch).to eq 1
        end
      end
    end

    describe '#count_wikis_checksum_mismatch' do
      before do
        create(:geo_project_registry, :repository_checksum_mismatch, :wiki_checksum_mismatch, project: project)
        create(:geo_project_registry, :repository_checksum_mismatch, project: project_1_in_synced_group)
        create(:geo_project_registry, :wiki_checksum_mismatch, project: project_2_in_synced_group)
        create(:geo_project_registry, :repository_verified, :wiki_checksum_mismatch, project: project_4_broken_storage)
      end

      it 'counts registries that wiki mismatch' do
        expect(subject.count_wikis_checksum_mismatch).to eq 3
      end

      context 'with selective sync by namespace' do
        it 'counts mismatch registries where projects belongs to the namespaces' do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          expect(subject.count_wikis_checksum_mismatch).to eq 1
        end
      end

      context 'with selective sync by shard' do
        it 'counts mismatch registries where projects belongs to the shards' do
          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

          expect(subject.count_wikis_checksum_mismatch).to eq 1
        end
      end
    end
  end

  shared_examples 'delegates to the proper finder' do |legacy_finder_klass, finder_klass, method, args|
    where(:selective_sync, :fdw_enabled, :fdw_for_selective_sync, :finder) do
      false | false | false | legacy_finder_klass
      false | false | true  | legacy_finder_klass
      false | true  | true  | finder_klass
      false | true  | false | finder_klass
      true  | false | false | legacy_finder_klass
      true  | false | true  | legacy_finder_klass
      true  | true  | true  | finder_klass
      true  | true  | false | legacy_finder_klass
    end

    with_them do
      before do
        stub_fdw(fdw_enabled)
        stub_feature_flags(use_fdw_queries_for_selective_sync: fdw_for_selective_sync)
        stub_selective_sync(secondary, selective_sync)
      end

      it 'delegates to the proper finder' do
        expect_next_instance_of(finder) do |finder|
          expect(finder).to receive(:execute).once
        end

        subject.public_send(method, *args)
      end
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  context 'FDW', :delete do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    end

    context 'with use_fdw_queries_for_selective_sync disabled' do
      before do
        stub_feature_flags(use_fdw_queries_for_selective_sync: false)
      end

      include_examples 'counts all the things', 'fdw'
    end

    context 'with use_fdw_queries_for_selective_sync enabled' do
      before do
        stub_feature_flags(use_fdw_queries_for_selective_sync: true)
      end

      include_examples 'counts all the things', 'fdw'
    end
  end

  context 'Legacy' do
    before do
      stub_fdw_disabled
    end

    include_examples 'counts all the things', 'legacy'
  end

  describe '#find_unsynced_projects', :delete do
    include_examples 'delegates to the proper finder',
      Geo::LegacyProjectUnsyncedFinder,
      Geo::ProjectUnsyncedFinder,
      :find_unsynced_projects, [shard_name: 'default', batch_size: 100]
  end

  describe '#find_projects_updated_recently', :delete do
    include_examples 'delegates to the proper finder',
      Geo::LegacyProjectUpdatedRecentlyFinder,
      Geo::ProjectUpdatedRecentlyFinder,
      :find_projects_updated_recently, [shard_name: 'default', batch_size: 100]
  end

  describe '#find_failed_project_registries', :delete do
    include_examples 'delegates to the proper finder',
      Geo::LegacyProjectRegistrySyncFailedFinder,
      Geo::ProjectRegistrySyncFailedFinder,
      :find_failed_project_registries, ['repository']
  end

  describe '#find_registries_to_verify', :delete do
    include_examples 'delegates to the proper finder',
      Geo::LegacyProjectRegistryPendingVerificationFinder,
      Geo::ProjectRegistryPendingVerificationFinder,
      :find_registries_to_verify, [shard_name: 'default', batch_size: 100]
  end

  describe '#find_verification_failed_project_registries', :delete do
    include_examples 'delegates to the proper finder',
      Geo::LegacyProjectRegistryVerificationFailedFinder,
      Geo::ProjectRegistryVerificationFailedFinder,
      :find_verification_failed_project_registries, ['repository']
  end

  describe '#find_checksum_mismatch_project_registries', :delete do
    include_examples 'delegates to the proper finder',
      Geo::LegacyProjectRegistryMismatchFinder,
      Geo::ProjectRegistryMismatchFinder,
      :find_checksum_mismatch_project_registries, ['repository']
  end
end
