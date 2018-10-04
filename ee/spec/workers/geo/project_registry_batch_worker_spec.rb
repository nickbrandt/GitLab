# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geo::ProjectRegistryBatchWorker do
  include ExclusiveLeaseHelpers
  include ::EE::GeoHelpers

  set(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)
  end

  describe '#perform' do
    context 'when operation is :recheck_repositories' do
      let!(:registry) { create(:geo_project_registry, :repository_verified) }

      it 'flags repositories for recheck' do
        Sidekiq::Testing.inline! do
          subject.perform(:recheck_repositories)
        end

        expect(registry.reload.repository_verification_pending?).to be_truthy
      end

      it 'does nothing if exclusive lease is already acquired' do
        stub_exclusive_lease_taken('geo/project_registry_batch_worker', timeout: 20)

        Sidekiq::Testing.inline! do
          subject.perform(:recheck_repositories)
        end

        expect(registry).to have_attributes(registry.reload.attributes)
      end
    end

    context 'when operation is :resync_repositories' do
      let!(:registry) { create(:geo_project_registry, :synced) }

      it 'flags repositories for resync' do
        Sidekiq::Testing.inline! do
          subject.perform(:resync_repositories)
        end

        expect(registry.reload.resync_repository?).to be_truthy
      end

      it 'does nothing if exclusive lease is already acquired' do
        stub_exclusive_lease_taken('geo/project_registry_batch_worker', timeout: 20)

        Sidekiq::Testing.inline! do
          subject.perform(:recheck_repositories)
        end

        expect(registry).to have_attributes(registry.reload.attributes)
      end
    end

    context 'when informed operation is unknown/invalid' do
      it 'fails with ArgumentError' do
        expect { subject.perform(:unknown_operation) }.to raise_error(ArgumentError)
      end
    end
  end
end
