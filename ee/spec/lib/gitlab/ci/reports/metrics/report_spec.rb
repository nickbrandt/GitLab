# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Metrics::Report do
  let(:report) { described_class.new }

  describe '#add_metric' do
    let(:metric_params) { %w[metric_name metric_value] }

    subject { report.add_metric(*metric_params) }

    it 'stores given metric' do
      subject

      expect(report.metrics.count).to eq(1)
    end

    it 'correctly stores metric params' do
      subject

      metric = report.metrics.first
      expect(metric.name).to eq(metric_params.first)
      expect(metric.value).to eq(metric_params.second)
    end
  end
end
