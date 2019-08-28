# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::ClusterProcessor do
  let(:cluster_project) { build(:cluster_project) }
  let(:cluster) { cluster_project.cluster }
  let(:project) { cluster_project.project }
  let(:dashboard_yml) { YAML.load_file('spec/fixtures/lib/gitlab/metrics/dashboard/sample_dashboard.yml') }

  describe 'process' do
    let(:process_params) { [project, dashboard_yml, { cluster: cluster, cluster_type: :project }] }
    let(:dashboard) { described_class.new(*process_params).process }

    it 'includes a path for the prometheus endpoint with each metric' do
      expect(all_metrics).to satisfy_all do |metric|
        metric[:prometheus_endpoint_path] == prometheus_path(metric[:query_range])
      end
    end

    context 'when dashboard config corresponds to common metrics' do
      let!(:common_metric) { create(:prometheus_metric, :common, identifier: 'metric_a1') }

      it 'inserts metric ids into the config' do
        target_metric = all_metrics.find { |metric| metric[:id] == 'metric_a1' }

        expect(target_metric).to include(:metric_id)
        expect(target_metric[:metric_id]).to eq(common_metric.id)
      end
    end

    shared_examples_for 'errors with message' do |expected_message|
      it 'raises a DashboardLayoutError' do
        error_class = Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError
        expect { dashboard }.to raise_error(error_class, expected_message)
      end
    end

    context 'when the dashboard is missing panel_groups' do
      let(:dashboard_yml) { {} }

      it_behaves_like 'errors with message', 'Top-level key :panel_groups must be an array'
    end

    context 'when the dashboard contains a panel_group which is missing panels' do
      let(:dashboard_yml) { { panel_groups: [{}] } }

      it_behaves_like 'errors with message', 'Each "panel_group" must define an array :panels'
    end

    context 'when the dashboard contains a panel which is missing metrics' do
      let(:dashboard_yml) { { panel_groups: [{ panels: [{}] }] } }

      it_behaves_like 'errors with message', 'Each "panel" must define an array :metrics'
    end

    context 'when the dashboard contains a metric which is missing a query' do
      let(:dashboard_yml) { { panel_groups: [{ panels: [{ metrics: [{}] }] }] } }

      it_behaves_like 'errors with message', 'Each "metric" must define one of :query or :query_range'
    end
  end

  private

  def all_metrics
    dashboard[:panel_groups].flat_map do |group|
      group[:panels].flat_map { |panel| panel[:metrics] }
    end
  end

  def get_metric_details(metric)
    {
      query_range: metric.query,
      unit: metric.unit,
      label: metric.legend,
      metric_id: metric.id,
      prometheus_endpoint_path: prometheus_path(metric.query)
    }
  end

  def prometheus_path(query)
    Gitlab::Routing.url_helpers.prometheus_api_project_cluster_path(
      project,
      cluster,
      proxy_path: :query_range,
      query: query
    )
  end
end
