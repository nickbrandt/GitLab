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
  let!(:project_not_synced) { create(:project) }
  let(:project_synced) { create(:project) }
  let(:project_repository_dirty) { create(:project) }
  let(:project_wiki_dirty) { create(:project) }
  let(:project_repository_verified) { create(:project) }
  let(:project_repository_verification_failed) { create(:project) }
  let(:project_wiki_verified) { create(:project) }
  let(:project_wiki_verification_failed) { create(:project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'counts all the things' do |method_prefix|
    describe '#count_synced_repositories' do
      it 'counts repositories that have been synced' do
        create(:geo_project_registry, :sync_failed)
        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        expect(subject.count_synced_repositories).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts projects that has been synced' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :synced, project: project_synced)
          create(:geo_project_registry, :synced, project: project_1_in_synced_group)
          create(:geo_project_registry, :sync_failed, project: project_2_in_synced_group)

          expect(subject.count_synced_repositories).to eq 1
        end
      end
    end

    describe '#count_synced_wikis' do
      it 'counts wiki that have been synced' do
        create(:geo_project_registry, :sync_failed)
        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        expect(subject.count_synced_wikis).to eq 2
      end

      it 'counts synced wikis with nil wiki_access_level (which means enabled wiki)' do
        project_synced.project_feature.update!(wiki_access_level: nil)

        create(:geo_project_registry, :synced, project: project_synced)

        expect(subject.count_synced_wikis).to eq 1
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts projects that has been synced' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :synced, project: project_synced)
          create(:geo_project_registry, :synced, project: project_1_in_synced_group)
          create(:geo_project_registry, :sync_failed, project: project_2_in_synced_group)

          expect(subject.count_synced_wikis).to eq 1
        end
      end
    end

    describe '#count_failed_repositories' do
      before do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)
        project_3_in_synced_group = create(:project, group: synced_group)
        project_4_broken_storage = create(:project, :broken_storage)

        create(:geo_project_registry, :synced, project: project_synced)
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
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)
        project_3_in_synced_group = create(:project, group: synced_group)
        project_4_broken_storage = create(:project, :broken_storage)

        create(:geo_project_registry, :synced, project: project_synced)
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
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)
        project_3_in_synced_group = create(:project, group: synced_group)
        project_4_broken_storage = create(:project, :broken_storage)

        create(:geo_project_registry, :repository_verified, :wiki_verified, project: project_synced)
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
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)
        project_3_in_synced_group = create(:project, group: synced_group)
        project_4_broken_storage = create(:project, :broken_storage)

        create(:geo_project_registry, :wiki_verified, :wiki_verified, project: project_synced)
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
      it 'counts projects that verification has failed' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verification_failed_repositories).to eq 1
      end
    end

    describe '#count_verification_failed_wikis' do
      it 'counts projects that verification has failed' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verification_failed_wikis).to eq 1
      end
    end

    describe '#count_repositories_retrying_verification' do
      before do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :repository_retrying_verification, :wiki_retrying_verification, project: project_synced)
        create(:geo_project_registry, :repository_retrying_verification, project: project_1_in_synced_group)
        create(:geo_project_registry, :wiki_retrying_verification, project: project_2_in_synced_group)
      end

      it 'counts registries that repository retrying verification' do
        expect(subject.count_repositories_retrying_verification).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts registries that repository retrying verification' do
          expect(subject.count_repositories_retrying_verification).to eq 1
        end
      end
    end

    describe '#count_wikis_retrying_verification' do
      before do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :repository_retrying_verification, :wiki_retrying_verification, project: project_synced)
        create(:geo_project_registry, :repository_retrying_verification, project: project_1_in_synced_group)
        create(:geo_project_registry, :wiki_retrying_verification, project: project_2_in_synced_group)
      end

      it 'counts registries that wiki retrying verification' do
        expect(subject.count_wikis_retrying_verification).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts registries that wiki retrying verification' do
          expect(subject.count_wikis_retrying_verification).to eq 1
        end
      end
    end

    describe '#count_repositories_checksum_mismatch' do
      let(:project_1_in_synced_group) { create(:project, group: synced_group) }
      let(:project_2_in_synced_group) { create(:project, group: synced_group) }

      let!(:registry_mismatch) { create(:geo_project_registry, :repository_checksum_mismatch, :wiki_checksum_mismatch, project: project_synced) }
      let!(:repository_mismatch) { create(:geo_project_registry, :repository_checksum_mismatch, project: project_1_in_synced_group) }
      let!(:wiki_mismatch) { create(:geo_project_registry, :wiki_checksum_mismatch, project: project_2_in_synced_group) }

      it 'counts registries that repository mismatch' do
        expect(subject.count_repositories_checksum_mismatch).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts projects that sync has failed' do
          expect(subject.count_repositories_checksum_mismatch).to eq 1
        end
      end
    end

    describe '#count_wikis_checksum_mismatch' do
      let(:project_1_in_synced_group) { create(:project, group: synced_group) }
      let(:project_2_in_synced_group) { create(:project, group: synced_group) }

      let!(:registry_mismatch) { create(:geo_project_registry, :repository_checksum_mismatch, :wiki_checksum_mismatch, project: project_synced) }
      let!(:repository_mismatch) { create(:geo_project_registry, :repository_checksum_mismatch, project: project_1_in_synced_group) }
      let!(:wiki_mismatch) { create(:geo_project_registry, :wiki_checksum_mismatch, project: project_2_in_synced_group) }

      it 'counts projects that verification has failed' do
        expect(subject.count_wikis_checksum_mismatch).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts projects that sync has failed' do
          expect(subject.count_wikis_checksum_mismatch).to eq 1
        end
      end
    end
  end

  shared_examples 'finds all the things' do |method_prefix|
    describe '#find_unsynced_projects' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_unsynced_projects".to_sym).and_call_original

        subject.find_unsynced_projects(batch_size: 10)
      end

      it 'returns projects without an entry on the tracking database' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)

        projects = subject.find_unsynced_projects(batch_size: 10)

        expect(projects).to match_ids(project_not_synced)
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_unsynced_projects' do
          expect(subject).to receive(:legacy_find_unsynced_projects).and_call_original

          subject.find_unsynced_projects(batch_size: 10)
        end

        it 'returns untracked projects in the synced group' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :sync_failed, project: project_1_in_synced_group)

          projects = subject.find_unsynced_projects(batch_size: 10)

          expect(projects).to match_ids(project_2_in_synced_group)
        end
      end
    end

    describe '#find_projects_updated_recently' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_projects_updated_recently".to_sym).and_call_original

        subject.find_projects_updated_recently(batch_size: 10)
      end

      it 'returns projects with a dirty entry on the tracking database' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        projects = subject.find_projects_updated_recently(batch_size: 10)

        expect(projects).to match_ids([project_repository_dirty, project_wiki_dirty])
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_projects_updated_recently' do
          expect(subject).to receive(:legacy_find_projects_updated_recently).and_call_original

          subject.find_projects_updated_recently(batch_size: 10)
        end

        it 'returns dirty projects in the synced group' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)
          project_3_in_synced_group = create(:project, group: synced_group)
          create(:project, group: synced_group)

          create(:geo_project_registry, :synced, :repository_dirty, project: project_1_in_synced_group)
          create(:geo_project_registry, :synced, :wiki_dirty, project: project_2_in_synced_group)
          create(:geo_project_registry, :synced, project: project_3_in_synced_group)

          projects = subject.find_projects_updated_recently(batch_size: 10)

          expect(projects).to match_ids(project_1_in_synced_group, project_2_in_synced_group)
        end
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
      include_examples 'finds all the things', 'fdw'
    end

    context 'with use_fdw_queries_for_selective_sync enabled' do
      before do
        stub_feature_flags(use_fdw_queries_for_selective_sync: true)
      end

      include_examples 'counts all the things', 'fdw'
      include_examples 'finds all the things', 'fdw'
    end
  end

  context 'Legacy' do
    before do
      stub_fdw_disabled
    end

    include_examples 'counts all the things', 'legacy'
    include_examples 'finds all the things', 'legacy'
  end

  describe '#find_failed_project_registries', :delete do
    where(:selective_sync, :fdw_enabled, :use_fdw_queries_for_selective_sync, :finder) do
      false | false | false | Geo::LegacyProjectRegistrySyncFailedFinder
      false | false | true  | Geo::LegacyProjectRegistrySyncFailedFinder
      false | true  | true  | Geo::ProjectRegistrySyncFailedFinder
      false | true  | false | Geo::ProjectRegistrySyncFailedFinder
      true  | false | false | Geo::LegacyProjectRegistrySyncFailedFinder
      true  | false | true  | Geo::LegacyProjectRegistrySyncFailedFinder
      true  | true  | true  | Geo::ProjectRegistrySyncFailedFinder
      true  | true  | false | Geo::LegacyProjectRegistrySyncFailedFinder
    end

    with_them do
      before do
        stub_geo_environment(secondary, selective_sync, fdw_enabled, use_fdw_queries_for_selective_sync)
      end

      it 'delegates to the correct finder' do
        expect_next_instance_of(finder, current_node: secondary, type: 'repository') do |finder|
          expect(finder).to receive(:execute).once
        end

        subject.find_failed_project_registries('repository')
      end
    end
  end

  describe '#find_registries_to_verify', :delete do
    where(:selective_sync, :fdw_enabled, :use_fdw_queries_for_selective_sync, :finder) do
      false | false | false | Geo::LegacyProjectRegistryPendingVerificationFinder
      false | false | true  | Geo::LegacyProjectRegistryPendingVerificationFinder
      false | true  | true  | Geo::ProjectRegistryPendingVerificationFinder
      false | true  | false | Geo::ProjectRegistryPendingVerificationFinder
      true  | false | false | Geo::LegacyProjectRegistryPendingVerificationFinder
      true  | false | true  | Geo::LegacyProjectRegistryPendingVerificationFinder
      true  | true  | true  | Geo::ProjectRegistryPendingVerificationFinder
      true  | true  | false | Geo::LegacyProjectRegistryPendingVerificationFinder
    end

    with_them do
      before do
        stub_geo_environment(secondary, selective_sync, fdw_enabled, use_fdw_queries_for_selective_sync)
      end

      it 'delegates to Geo::ProjectRegistryPendingVerificationFinder' do
        expect_next_instance_of(finder, current_node: secondary, shard_name: 'default', batch_size: 100) do |finder|
          expect(finder).to receive(:execute).once
        end

        subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)
      end
    end
  end

  describe '#find_checksum_mismatch_project_registries', :delete do
    where(:selective_sync, :fdw_enabled, :use_fdw_queries_for_selective_sync, :finder) do
      false | false | false | Geo::LegacyProjectRegistryMismatchFinder
      false | false | true  | Geo::LegacyProjectRegistryMismatchFinder
      false | true  | true  | Geo::ProjectRegistryMismatchFinder
      false | true  | false | Geo::ProjectRegistryMismatchFinder
      true  | false | false | Geo::LegacyProjectRegistryMismatchFinder
      true  | false | true  | Geo::LegacyProjectRegistryMismatchFinder
      true  | true  | true  | Geo::ProjectRegistryMismatchFinder
      true  | true  | false | Geo::LegacyProjectRegistryMismatchFinder
    end

    with_them do
      before do
        stub_geo_environment(secondary, selective_sync, fdw_enabled, use_fdw_queries_for_selective_sync)
      end

      it 'delegates to the correct finder' do
        expect_next_instance_of(finder, current_node: secondary, type: 'repository') do |finder|
          expect(finder).to receive(:execute).once
        end

        subject.find_checksum_mismatch_project_registries('repository')
      end
    end
  end

  describe '#find_verification_failed_project_registries', :delete do
    where(:selective_sync, :fdw_enabled, :use_fdw_queries_for_selective_sync, :finder) do
      false | false | false | Geo::LegacyProjectRegistryVerificationFailedFinder
      false | false | true  | Geo::LegacyProjectRegistryVerificationFailedFinder
      false | true  | true  | Geo::ProjectRegistryVerificationFailedFinder
      false | true  | false | Geo::ProjectRegistryVerificationFailedFinder
      true  | false | false | Geo::LegacyProjectRegistryVerificationFailedFinder
      true  | false | true  | Geo::LegacyProjectRegistryVerificationFailedFinder
      true  | true  | true  | Geo::ProjectRegistryVerificationFailedFinder
      true  | true  | false | Geo::LegacyProjectRegistryVerificationFailedFinder
    end

    with_them do
      before do
        stub_geo_environment(secondary, selective_sync, fdw_enabled, use_fdw_queries_for_selective_sync)
      end

      it 'delegates to the correct finder' do
        expect_next_instance_of(finder, current_node: secondary, type: 'repository') do |finder|
          expect(finder).to receive(:execute).once
        end

        subject.find_verification_failed_project_registries('repository')
      end
    end
  end

  def stub_geo_environment(node, selective_sync, fdw_enabled, use_fdw_queries_for_selective_sync)
    stub_fdw(fdw_enabled)
    stub_feature_flags(use_fdw_queries_for_selective_sync: use_fdw_queries_for_selective_sync)
    stub_selective_sync(node, selective_sync)
  end
end
