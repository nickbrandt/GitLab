# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRegistryPendingVerificationFinder, :geo, :geo_fdw do
  describe '#execute' do
    let(:node) { create(:geo_node) }

    subject { described_class.new(current_node: node, shard_name: 'default', batch_size: 100) }

    it 'does not return registries that are verified on primary and secondary' do
      project_verified    = create(:repository_state, :repository_verified, :wiki_verified).project
      repository_verified = create(:repository_state, :repository_verified).project
      wiki_verified       = create(:repository_state, :wiki_verified).project

      create(:geo_project_registry, :repository_verified, :wiki_verified, project: project_verified)
      create(:geo_project_registry, :repository_verified, project: repository_verified)
      create(:geo_project_registry, :wiki_verified, project: wiki_verified)

      expect(subject.execute).to be_empty
    end

    it 'does not return registries that were unverified/outdated on primary' do
      project_unverified_primary  = create(:project)
      project_outdated_primary    = create(:repository_state, :repository_outdated, :wiki_outdated).project
      repository_outdated_primary = create(:repository_state, :repository_outdated, :wiki_verified).project
      wiki_outdated_primary       = create(:repository_state, :repository_verified, :wiki_outdated).project

      create(:geo_project_registry, project: project_unverified_primary)
      create(:geo_project_registry, :repository_verification_outdated, :wiki_verification_outdated, project: project_outdated_primary)
      create(:geo_project_registry, :repository_verified, :wiki_verified, project: repository_outdated_primary)
      create(:geo_project_registry, :repository_verified, :wiki_verified, project: wiki_outdated_primary)

      expect(subject.execute).to be_empty
    end

    it 'returns registries that were unverified/outdated on secondary' do
      project_unverified_secondary  = create(:repository_state, :repository_verified, :wiki_verified).project
      project_outdated_secondary    = create(:repository_state, :repository_verified, :wiki_verified).project
      repository_outdated_secondary = create(:repository_state, :repository_verified, :wiki_verified).project
      wiki_outdated_secondary       = create(:repository_state, :repository_verified, :wiki_verified).project

      registry_unverified_secondary          = create(:geo_project_registry, :synced, project: project_unverified_secondary)
      registry_outdated_secondary            = create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verification_outdated, project: project_outdated_secondary)
      registry_repository_outdated_secondary = create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verified, project: repository_outdated_secondary)
      registry_wiki_outdated_secondary       = create(:geo_project_registry, :synced, :repository_verified, :wiki_verification_outdated, project: wiki_outdated_secondary)

      expect(subject.execute)
        .to contain_exactly(
          registry_unverified_secondary,
          registry_outdated_secondary,
          registry_repository_outdated_secondary,
          registry_wiki_outdated_secondary
        )
    end

    it 'does not return registries that failed on primary' do
      verification_failed_primary = create(:repository_state, :repository_failed, :wiki_failed).project

      create(:geo_project_registry, project: verification_failed_primary)

      expect(subject.execute).to be_empty
    end

    it 'returns registries where one failed and one verified on the primary' do
      verification_failed_primary = create(:repository_state, :repository_failed, :wiki_failed).project
      repository_failed_primary   = create(:repository_state, :repository_failed, :wiki_verified).project
      wiki_failed_primary         = create(:repository_state, :repository_verified, :wiki_failed).project

      create(:geo_project_registry, :synced, project: verification_failed_primary)
      registry_repository_failed_primary = create(:geo_project_registry, :synced, project: repository_failed_primary)
      registry_wiki_failed_primary       = create(:geo_project_registry, :synced, project: wiki_failed_primary)

      expect(subject.execute)
        .to contain_exactly(
          registry_repository_failed_primary,
          registry_wiki_failed_primary
        )
    end

    it 'does not return registries where verification failed on secondary' do
      verification_failed_secondary = create(:repository_state, :repository_verified, :wiki_verified).project
      repository_failed_secondary   = create(:repository_state, :repository_verified).project
      wiki_failed_secondary         = create(:repository_state, :wiki_verified).project

      create(:geo_project_registry, :repository_verification_failed, :wiki_verification_failed, project: verification_failed_secondary)
      create(:geo_project_registry, :repository_verification_failed, project: repository_failed_secondary)
      create(:geo_project_registry, :wiki_verification_failed, project: wiki_failed_secondary)

      expect(subject.execute).to be_empty
    end

    it 'does not return registries when the repo needs to be resynced' do
      project_verified = create(:repository_state, :repository_verified).project
      create(:geo_project_registry, :repository_sync_failed, project: project_verified)

      expect(subject.execute).to be_empty
    end

    it 'does not return registries when the wiki needs to be resynced' do
      project_verified = create(:repository_state, :wiki_verified).project
      create(:geo_project_registry, :wiki_sync_failed, project: project_verified)

      expect(subject.execute).to be_empty
    end

    it 'does not return registries when the repository is missing on primary' do
      project_verified = create(:repository_state, :repository_verified).project
      create(:geo_project_registry, :synced, project: project_verified, repository_missing_on_primary: true)

      expect(subject.execute).to be_empty
    end

    it 'does not return registries when the wiki is missing on primary' do
      project_verified = create(:repository_state, :wiki_verified).project
      create(:geo_project_registry, :synced, project: project_verified, wiki_missing_on_primary: true)

      expect(subject.execute).to be_empty
    end

    it 'does not return registries where projects belongs to other shards' do
      project_broken_storage = create(:project, :broken_storage)
      create(:repository_state, :repository_verified, :wiki_verified, project: project_broken_storage)
      create(:geo_project_registry, :synced, project: project_broken_storage)

      expect(subject.execute).to be_empty
    end

    context 'with selective sync by namespace' do
      it 'returns registries where projects belongs to the namespaces' do
        group_1 = create(:group)
        group_2 = create(:group)
        nested_group_1 = create(:group, parent: group_1)
        project_1 = create(:project, group: group_1)
        project_2 = create(:project, group: nested_group_1)
        project_3 = create(:project, group: group_2)

        create(:repository_state, :repository_verified, :wiki_verified, project: project_1)
        create(:repository_state, :repository_verified, :wiki_verified, project: project_2)
        create(:repository_state, :repository_verified, :wiki_verified, project: project_3)

        registry_unverified_secondary = create(:geo_project_registry, :synced, project: project_1)
        registry_outdated_secondary = create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verification_outdated, project: project_2)
        create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verified, project: project_3)

        node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

        expect(subject.execute)
          .to contain_exactly(
            registry_unverified_secondary,
            registry_outdated_secondary
          )
      end
    end

    context 'with selective sync by shard' do
      let(:project_broken_storage) { create(:project, :broken_storage) }
      let!(:repository_state_project_broken_storage) { create(:repository_state, :repository_verified, :wiki_verified, project: project_broken_storage) }
      let!(:registry_repository_broken_shard) { create(:geo_project_registry, :synced, project: project_broken_storage) }

      let(:project) { create(:project) }
      let!(:project_unverified_secondary) { create(:repository_state, :repository_verified, :wiki_verified, project: project) }
      let!(:registry_unverified_secondary) { create(:geo_project_registry, :synced, project: project) }

      before do
        node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
      end

      it 'does not return registries when selected shards to sync does not include the shard_name' do
        subject = described_class.new(current_node: node, shard_name: 'default', batch_size: 100)

        expect(subject.execute).to be_empty
      end

      it 'returns registries where projects belongs to the shards' do
        subject = described_class.new(current_node: node, shard_name: 'broken', batch_size: 100)

        expect(subject.execute).to contain_exactly(registry_repository_broken_shard)
      end
    end
  end
end
