# frozen_string_literal: true

require 'spec_helper'

describe Geo::ContainerRepositorySyncWorker, :geo do
  describe '#perform' do
    it 'runs ContainerRepositorySyncService' do
      container_repository = create(:container_repository)
      service = spy(:service)

      expect(Geo::ContainerRepositorySyncService).to receive(:new).with(container_repository).and_return(service)

      described_class.new.perform(container_repository.id)

      expect(service).to have_received(:execute)
    end

    it 'does not run ContainerRepositorySyncService if feature disabled' do
      stub_feature_flags(geo_registry_replication: false)

      container_repository = create(:container_repository)

      expect(Geo::ContainerRepositorySyncService).not_to receive(:new).with(container_repository)

      described_class.new.perform(container_repository.id)
    end

    it 'logs error when repository does not exist' do
      worker = described_class.new

      expect(worker).to receive(:log_error)
        .with("Couldn't find container repository, skipping syncing", container_repository_id: 20)

      expect(Geo::ContainerRepositorySyncService).not_to receive(:new)

      worker.perform(20)
    end
  end
end
