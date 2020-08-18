# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogCursor::Events::ContainerRepositoryUpdatedEvent, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:selective_sync_secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['non-existent']) }
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :container_repository_updated_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:container_repository_updated_event) { event_log.container_repository_updated_event }
  let(:container_repository) { container_repository_updated_event.container_repository }

  subject { described_class.new(container_repository_updated_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before do
    stub_current_geo_node(secondary)
  end

  describe '#process' do
    context 'when container repository replication is enabled' do
      before do
        stub_config(geo: { registry_replication: { enabled: true } })
      end

      context 'when a registry does not yet exist' do
        context "when the container repository's project is not excluded by selective sync" do
          # TODO: Fix the bug and un-x the test https://gitlab.com/gitlab-org/gitlab/-/issues/233514
          xit 'creates a registry' do
            expect { subject.process }.to change(Geo::ContainerRepositoryRegistry, :count).by(1)
          end

          it_behaves_like 'event schedules a sync worker', ::Geo::ContainerRepositorySyncWorker do
            let(:expected_id) { container_repository.id }
          end

          it_behaves_like 'logs event source info'
        end

        context "when the container repository's project is excluded by selective sync" do
          before do
            stub_current_geo_node(selective_sync_secondary)
          end

          it_behaves_like 'event does not create a registry', ::Geo::ContainerRepositoryRegistry
          it_behaves_like 'event does not schedule a sync worker', ::Geo::ContainerRepositorySyncWorker
          it_behaves_like 'logs event source info'
        end
      end

      context 'when a registry exists' do
        let!(:registry) { create(:geo_container_repository_registry, :synced) }

        context "when the container repository's project is not excluded by selective sync" do
          # TODO: Fix the bug and un-x the test https://gitlab.com/gitlab-org/gitlab/-/issues/233514
          xit 'transitions the registry to pending' do
            expect { subject.process }.to change(registry, :pending?).to(true)
          end

          it_behaves_like 'event schedules a sync worker', ::Geo::ContainerRepositorySyncWorker do
            let(:expected_id) { container_repository.id }
          end

          it_behaves_like 'logs event source info'
        end

        context "when the container repository's project is excluded by selective sync" do
          before do
            stub_current_geo_node(selective_sync_secondary)
          end

          it 'does not transition the registry to pending state' do
            expect { subject.process }.not_to change(registry, :pending?)
          end

          it_behaves_like 'event does not schedule a sync worker', ::Geo::ContainerRepositorySyncWorker
          it_behaves_like 'logs event source info'
        end
      end
    end

    context 'when container repository replication is disabled' do
      before do
        stub_config(geo: { registry_replication: { enabled: false } })
      end

      context "even when the container repository's project is not excluded by selective sync" do
        it_behaves_like 'event does not create a registry', ::Geo::ContainerRepositoryRegistry
        it_behaves_like 'event does not schedule a sync worker', ::Geo::ContainerRepositorySyncWorker
        it_behaves_like 'logs event source info'
      end
    end
  end
end
