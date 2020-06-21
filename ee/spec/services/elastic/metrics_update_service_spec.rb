# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MetricsUpdateService, :prometheus do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
  end

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    def setup_gauge_double(processor, gauge, queue_size)
      gauge_double = instance_double(Prometheus::Client::Gauge)

      allow(Elastic::ProcessBookkeepingService).to receive(:queue_size).with(processor: processor).and_return(queue_size)
      allow(Gitlab::Metrics).to receive(:gauge)
                                  .with(gauge, anything, {}, :max)
                                  .and_return(gauge_double)

      expect(gauge_double).to receive(:set).with({}, queue_size)
    end

    it 'sets gauges' do
      setup_gauge_double(::Gitlab::Elastic::BulkIndexer::InitialProcessor, :global_search_bulk_project_initial_queue_size, 1)
      setup_gauge_double(::Gitlab::Elastic::BulkIndexer::IncrementalProcessor, :global_search_bulk_project_incremental_queue_size, 5)
      setup_gauge_double(::Gitlab::Elastic::Indexer::InitialProcessor, :global_search_bulk_repository_initial_queue_size, 10)
      setup_gauge_double(::Gitlab::Elastic::Indexer::IncrementalProcessor, :global_search_bulk_repository_incremental_queue_size, 15)
      setup_gauge_double(::Gitlab::Elastic::WikiIndexer::InitialProcessor, :global_search_bulk_wiki_initial_queue_size, 20)
      setup_gauge_double(::Gitlab::Elastic::WikiIndexer::IncrementalProcessor, :global_search_bulk_wiki_incremental_queue_size, 25)

      subject.execute
    end

    context 'when prometheus metrics is disabled' do
      before do
        allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(false)
      end

      it 'does not set a gauge' do
        expect(Gitlab::Metrics).not_to receive(:gauge)

        subject.execute
      end
    end

    context 'when elasticsearch indexing and search is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'does not set a gauge' do
        expect(Gitlab::Metrics).not_to receive(:gauge)

        subject.execute
      end
    end
  end
end
