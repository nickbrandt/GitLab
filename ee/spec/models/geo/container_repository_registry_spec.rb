# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryRegistry, :geo do
  it_behaves_like 'a BulkInsertSafe model', Geo::ContainerRepositoryRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:container_repository_registry, 10, created_at: Time.zone.now) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  let_it_be(:registry) { create(:container_repository_registry) }

  describe 'relationships' do
    it { is_expected.to belong_to(:container_repository) }
  end

  describe 'scopes' do
    describe '.repository_id_not_in' do
      it 'returns registries scoped by ids' do
        registry1 = create(:container_repository_registry)
        registry2 = create(:container_repository_registry)

        container_repository1_id = registry1.container_repository_id
        container_repository2_id = registry2.container_repository_id

        result = described_class.repository_id_not_in([container_repository1_id, container_repository2_id])

        expect(result).to match_ids([registry])
      end
    end
  end

  it_behaves_like 'a Geo registry' do
    let(:registry) { create(:container_repository_registry) }
  end

  describe '#finish_sync!' do
    let(:registry) { create(:container_repository_registry, :sync_started) }

    it 'finishes registry record' do
      registry.finish_sync!

      expect(registry.reload).to have_attributes(
        retry_count: 0,
        retry_at: nil,
        last_sync_failure: nil,
        state: 'synced'
      )
    end

    context 'when a container sync was scheduled after the last sync began' do
      before do
        registry.update!(
          state: 'pending',
          retry_count: 2,
          retry_at: 1.hour.ago,
          last_sync_failure: 'error'
        )

        registry.finish_sync!
      end

      it 'does not reset state' do
        expect(registry.reload.state).to eq 'pending'
      end

      it 'resets the other sync state fields' do
        expect(registry.reload).to have_attributes(
          retry_count: 0,
          retry_at: nil,
          last_sync_failure: nil
        )
      end
    end
  end

  describe '.replication_enabled?' do
    it 'returns true when registry replication is enabled' do
      stub_geo_setting(registry_replication: { enabled: true })

      expect(Geo::ContainerRepositoryRegistry.replication_enabled?).to be_truthy
    end

    it 'returns false when registry replication is disabled' do
      stub_geo_setting(registry_replication: { enabled: false })

      expect(Geo::ContainerRepositoryRegistry.replication_enabled?).to be_falsey
    end
  end
end
