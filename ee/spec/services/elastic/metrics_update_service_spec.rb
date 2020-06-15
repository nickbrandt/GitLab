# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MetricsUpdateService, :prometheus do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
  end

  describe '#execute' do
    it 'sets gauges' do
      expect(Elastic::ProcessBookkeepingService).to receive(:queue_size).and_return(4)
      expect(Elastic::ProcessInitialBookkeepingService).to receive(:queue_size).and_return(6)

      incremental_gauge_double = instance_double(Prometheus::Client::Gauge)
      expect(Gitlab::Metrics).to receive(:gauge)
        .with(:global_search_bulk_cron_queue_size, anything, {}, :max)
        .and_return(incremental_gauge_double)

      initial_gauge_double = instance_double(Prometheus::Client::Gauge)
      expect(Gitlab::Metrics).to receive(:gauge)
        .with(:global_search_bulk_cron_initial_queue_size, anything, {}, :max)
        .and_return(initial_gauge_double)

      expect(incremental_gauge_double).to receive(:set).with({}, 4)
      expect(initial_gauge_double).to receive(:set).with({}, 6)

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
