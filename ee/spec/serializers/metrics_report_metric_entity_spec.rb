# frozen_string_literal: true

require 'spec_helper'

describe MetricsReportMetricEntity do
  let(:metric) { ::Gitlab::Ci::Reports::Metrics::Metric.new('metric_name', 'metric_value') }
  let(:entity) { described_class.new(metric) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains the correct metric' do
      expect(subject[:name]).to eq('metric_name')
      expect(subject[:value]).to eq('metric_value')
    end
  end
end
