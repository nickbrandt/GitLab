# frozen_string_literal: true

require 'spec_helper'

describe PerformanceMonitoring::PrometheusPanel do
  let(:json_content) do
    {
      "type" => "area-chart",
      "title" => "Chart Title",
      "y_label" => "Y-Axis",
      "weight" => 1,
      "metrics" => [{
        "id" => "metric_of_ages",
        "unit" => "count",
        "label" => "Metric of Ages",
        "query_range" => "http_requests_total"
      }]
    }
  end

  describe '.from_json' do
    subject { described_class.from_json(json_content) }

    it 'creates a PrometheusPanelGroup object' do
      expect(subject).to be_a PerformanceMonitoring::PrometheusPanel
      expect(subject.type).to eq(json_content['type'])
      expect(subject.title).to eq(json_content['title'])
      expect(subject.y_label).to eq(json_content['y_label'])
      expect(subject.weight).to eq(json_content['weight'])
      expect(subject.metrics).to all(be_a PerformanceMonitoring::PrometheusMetric)
    end

    describe 'validations' do
      context 'when title is missing' do
        before do
          json_content['title'] = nil
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when metrics are missing' do
        before do
          json_content['metrics'] = []
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end
    end
  end
end
