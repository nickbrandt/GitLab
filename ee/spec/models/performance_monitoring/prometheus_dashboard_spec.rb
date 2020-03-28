# frozen_string_literal: true

require 'spec_helper'

describe PerformanceMonitoring::PrometheusDashboard do
  let(:json_content) do
    {
      "dashboard" => "Dashboard Title",
      "panel_groups" => [{
        "group" => "Group Title",
        "panels" => [{
          "type" => "area-chart",
          "title" => "Chart Title",
          "y_label" => "Y-Axis",
          "metrics" => [{
            "id" => "metric_of_ages",
            "unit" => "count",
            "label" => "Metric of Ages",
            "query_range" => "http_requests_total"
          }]
        }]
      }]
    }
  end

  describe '.from_json' do
    subject { described_class.from_json(json_content) }

    it 'creates a PrometheusDashboard object' do
      expect(subject).to be_a PerformanceMonitoring::PrometheusDashboard
      expect(subject.dashboard).to eq(json_content['dashboard'])
      expect(subject.panel_groups).to all(be_a PerformanceMonitoring::PrometheusPanelGroup)
    end

    describe 'validations' do
      context 'when dashboard is missing' do
        before do
          json_content['dashboard'] = nil
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when panel groups are missing' do
        before do
          json_content['panel_groups'] = []
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end
    end
  end

  describe '#to_yaml' do
    let(:expected_yaml) do
      "---\npanel_groups:\n- panels:\n  - metrics:\n    - id: metric_of_ages\n      unit: count\n      label: Metric of Ages\n      query: \n      query_range: http_requests_total\n    type: area-chart\n    title: Chart Title\n    y_label: Y-Axis\n    weight: \n  group: Group Title\n  priority: \ndashboard: Dashboard Title\n"
    end

    let(:prometheus_dashboard) { described_class.from_json(json_content) }

    let(:subject) { prometheus_dashboard.to_yaml }

    it { is_expected.to eq(expected_yaml) }
  end
end
