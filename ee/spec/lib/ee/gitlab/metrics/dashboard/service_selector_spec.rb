# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::ServiceSelector do
  include MetricsDashboardHelpers

  describe '#call' do
    subject { described_class.call(arguments) }

    context 'when cluster is provided' do
      let(:arguments) { { cluster: "some cluster" } }

      it { is_expected.to be Metrics::Dashboard::ClusterDashboardService }
    end

    context 'when cluster is provided and embedded is not true' do
      let(:arguments) { { cluster: "some cluster", embedded: 'false' } }

      it { is_expected.to be Metrics::Dashboard::ClusterDashboardService }
    end

    context 'when cluster dashboard_path is provided' do
      let(:arguments) { { dashboard_path: ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH } }

      it { is_expected.to be Metrics::Dashboard::ClusterDashboardService }
    end

    context 'when cluster is provided and embed params' do
      let(:arguments) do
        {
          cluster: "some cluster",
          embedded: 'true',
          cluster_type: 'project',
          format: :json,
          group: 'Food metrics',
          title: 'Pizza Consumption',
          y_label: 'Slice Count'
        }
      end

      it { is_expected.to be Metrics::Dashboard::ClusterMetricsEmbedService }
    end

    context 'when metrics embed is for an alert' do
      let(:arguments) { { embedded: true, prometheus_alert_id: 5 } }

      it { is_expected.to be Metrics::Dashboard::GitlabAlertEmbedService }
    end
  end
end
