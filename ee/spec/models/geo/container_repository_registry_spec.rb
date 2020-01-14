# frozen_string_literal: true

require 'spec_helper'

describe Geo::ContainerRepositoryRegistry, :geo do
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
end
