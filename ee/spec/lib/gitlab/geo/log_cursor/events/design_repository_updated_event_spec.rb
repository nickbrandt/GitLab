# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::DesignRepositoryUpdatedEvent, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:project) { create(:project) }
  let(:event) { create(:geo_design_repository_updated_event, project: project) }
  let(:event_log) { create(:geo_event_log, repository_updated_event: event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

  subject { described_class.new(event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'DesignRepositoryUpdatedEvent' do
    it 'creates a new registry when a design registry does not exist' do
      expect { subject.process }.to change(Geo::DesignRegistry, :count).by(1)
    end

    it 'marks registry as pending when a design registry exists' do
      registry = create(:geo_design_registry, :synced, project: project)

      expect { subject.process }.to change { registry.reload.state }.from('synced').to('pending')
    end
  end

  describe '#process' do
    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(enable_geo_design_sync: false)
      end

      it 'does not create a design registry' do
        expect { subject.process }.not_to change(Geo::DesignRegistry, :count)
      end

      it 'does not schedule a Geo::DesignRepositorySyncWorker job' do
        expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async).with(project.id)

        subject.process
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(enable_geo_design_sync: true)
      end

      context 'when the associated shard is healthy' do
        before do
          allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(true)
        end

        it_behaves_like 'DesignRepositoryUpdatedEvent'

        it 'schedules a Geo::DesignRepositorySyncWorker' do
          expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async).with(project.id).once

          subject.process
        end
      end

      context 'when associated shard is unhealthy' do
        before do
          allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(false)
        end

        it_behaves_like 'DesignRepositoryUpdatedEvent'

        it 'does not schedule a Geo::DesignRepositorySyncWorker job' do
          expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async).with(project.id)

          subject.process
        end
      end
    end
  end
end
