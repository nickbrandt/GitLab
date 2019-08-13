# frozen_string_literal: true

require 'spec_helper'

describe Geo::ContainerRepositorySyncService, :geo do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  set(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    let(:container_repository_registry) { create(:container_repository_registry, :started) }

    it 'fails registry record if there was exception' do
      allow_any_instance_of(Geo::ContainerRepositorySync)
        .to receive(:execute).and_raise 'Sync Error'

      described_class.new(container_repository_registry.container_repository).execute

      expect(container_repository_registry.reload.failed?).to be_truthy
    end

    it 'finishes registry record if there was no exception' do
      expect_any_instance_of(Geo::ContainerRepositorySync)
        .to receive(:execute)

      described_class.new(container_repository_registry.container_repository).execute

      expect(container_repository_registry.reload.synced?).to be_truthy
    end

    it 'finishes registry record if there was no exception and registy does not exist' do
      container_repository = create(:container_repository)

      expect_any_instance_of(Geo::ContainerRepositorySync)
        .to receive(:execute)

      described_class.new(container_repository).execute

      registry = Geo::ContainerRepositoryRegistry.find_by(container_repository_id: container_repository.id)

      expect(registry.synced?).to be_truthy
    end
  end
end
