require 'spec_helper'

describe Geo::RepositoriesCleanUpWorker do
  describe '#perform' do
    include ExclusiveLeaseHelpers

    let(:geo_node) { create(:geo_node) }

    before do
      stub_exclusive_lease
    end

    context 'when node has selective sync enabled' do
      let(:synced_group) { create(:group) }
      let(:geo_node) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

      context 'legacy storage' do
        it 'performs GeoRepositoryDestroyWorker for each project that does not belong to selected namespaces to replicate' do
          project_in_synced_group = create(:project, :legacy_storage, group: synced_group)
          unsynced_project = create(:project, :repository, :legacy_storage)
          disk_path = "#{unsynced_project.namespace.full_path}/#{unsynced_project.path}"

          expect(GeoRepositoryDestroyWorker).to receive(:perform_async)
            .with(unsynced_project.id, unsynced_project.name, disk_path, unsynced_project.repository.storage)
            .once.and_return(1)

          expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)
            .with(project_in_synced_group.id, project_in_synced_group.name, project_in_synced_group.disk_path, project_in_synced_group.repository.storage)

          subject.perform(geo_node.id)
        end
      end

      context 'hashed storage' do
        before do
          stub_application_setting(hashed_storage_enabled: true)
        end

        it 'performs GeoRepositoryDestroyWorker for each project that does not belong to selected namespaces to replicate' do
          project_in_synced_group = create(:project, group: synced_group)
          unsynced_project = create(:project, :repository)

          hash = Digest::SHA2.hexdigest(unsynced_project.id.to_s)
          disk_path = "@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}"

          expect(GeoRepositoryDestroyWorker).to receive(:perform_async)
            .with(unsynced_project.id, unsynced_project.name, disk_path, unsynced_project.repository.storage)
            .once.and_return(1)

          expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)
            .with(project_in_synced_group.id, project_in_synced_group.name, project_in_synced_group.disk_path, project_in_synced_group.repository.storage)

          subject.perform(geo_node.id)
        end
      end

      context 'when the project repository does not exist on disk' do
        let(:project) { create(:project) }

        it 'performs GeoRepositoryDestroyWorker' do
          expect(GeoRepositoryDestroyWorker).to receive(:perform_async)
            .with(project.id, anything, anything, anything)
            .once
            .and_return(1)

          subject.perform(geo_node.id)
        end

        it 'does not leave orphaned entries in the project_registry table' do
          create(:geo_project_registry, :sync_failed, project: project)

          Sidekiq::Testing.inline! do
            subject.perform(geo_node.id)
          end

          expect(Geo::ProjectRegistry.where(project_id: project)).to be_empty
        end
      end
    end

    it 'does not perform GeoRepositoryDestroyWorker when node does not selective sync enabled' do
      expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)

      subject.perform(geo_node.id)
    end

    it 'does not perform GeoRepositoryDestroyWorker when cannnot obtain a lease' do
      stub_exclusive_lease_taken

      expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)

      subject.perform(geo_node.id)
    end

    it 'does not raise an error when node could not be found' do
      expect { subject.perform(-1) }.not_to raise_error
    end
  end
end
