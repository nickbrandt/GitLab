# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogCursor::Events::ContainerRepositoryUpdatedEvent, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :container_repository_updated_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:container_repository_updated_event) { event_log.container_repository_updated_event }
  let(:container_repositoy) { container_repository_updated_event.container_repository }

  subject { described_class.new(container_repository_updated_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  describe '#process' do
    it 'does not create a new project registry' do
      expect { subject.process }.not_to change(Geo::ProjectRegistry, :count)
    end

    it 'schedules a Geo::ContainerRepositorySyncWorker' do
      expect(::Geo::ContainerRepositorySyncWorker).to receive(:perform_async)
        .with(container_repositoy.id)

      subject.process
    end

    it_behaves_like 'logs event source info'
  end
end
