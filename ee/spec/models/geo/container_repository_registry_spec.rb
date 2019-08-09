# frozen_string_literal: true

require 'spec_helper'

describe Geo::ContainerRepositoryRegistry, :geo do
  set(:container_repository_registry) { create(:container_repository_registry) }

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

        expect(result).to match_ids([container_repository_registry])
      end
    end
  end

  describe '#start_sync!' do
    it 'updates last_synced_at' do
      expect { container_repository_registry.start_sync! }
        .to change { container_repository_registry.reload.last_synced_at }
    end
  end

  describe '#finish_sync!' do
    it 'finishes registry record' do
      container_repository_registry = create(:container_repository_registry, :sync_started)

      container_repository_registry.finish_sync!

      expect(container_repository_registry.reload).to have_attributes(
        retry_count: 0,
        retry_at: nil,
        last_sync_failure: nil,
        state: 'synced'
      )
    end
  end

  describe '#fail_sync!' do
    it 'fails registry record' do
      error = StandardError.new('Something is wrong')

      container_repository_registry.fail_sync!('Failed', error)

      expect(container_repository_registry).to have_attributes(
        retry_count: 1,
        retry_at: be_present,
        last_sync_failure: 'Failed: Something is wrong',
        state: 'failed'
      )
    end
  end

  describe '#repository_updated!' do
    set(:container_repository_registry) { create(:container_repository_registry, :synced) }

    it 'resets the state of the sync' do
      container_repository_registry.repository_updated!

      expect(container_repository_registry.pending?).to be true
    end
  end
end
