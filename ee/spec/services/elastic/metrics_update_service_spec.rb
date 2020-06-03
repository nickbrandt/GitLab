# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MetricsUpdateService, :prometheus do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
  end

  describe '#execute' do
    it 'sets a gauge for global_search_bulk_cron_queue_size' do
      expect(Elastic::ProcessBookkeepingService).to receive(:queue_size).and_return(4)

      gauge_double = instance_double(Prometheus::Client::Gauge)
      expect(Gitlab::Metrics).to receive(:gauge)
        .with(:global_search_bulk_cron_queue_size, anything, {}, :max)
        .and_return(gauge_double)

      expect(gauge_double).to receive(:set).with({}, 4)

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
