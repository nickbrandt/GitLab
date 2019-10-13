# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Processor do
  let(:project) { build(:project) }
  let(:environment) { create(:environment, project: project) }
  let(:dashboard_yml) { YAML.load_file('spec/fixtures/lib/gitlab/metrics/dashboard/sample_dashboard.yml') }
  let(:params) { [project, dashboard_yml, sequence, { environment: environment }] }

  describe 'process' do
    let(:dashboard) { described_class.new(*params).process }
    let(:sequence) do
      [
        Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
        Gitlab::Metrics::Dashboard::Stages::ProjectMetricsInserter,
        Gitlab::Metrics::Dashboard::Stages::EndpointInserter,
        Gitlab::Metrics::Dashboard::Stages::Sorter,
        ::EE::Gitlab::Metrics::Dashboard::Stages::AlertsInserter
      ]
    end

    context 'when the dashboard references persisted metrics with alerts' do
      let!(:alert) do
        create(
          :prometheus_alert,
          environment: environment,
          project: project,
          prometheus_metric: persisted_metric
        )
      end

      shared_examples_for 'has saved alerts' do
        it 'includes an alert path' do
          target_metric = all_metrics.find { |metric| metric[:metric_id] == persisted_metric.id }

          expect(target_metric).to be_a Hash
          expect(target_metric).to include(:alert_path)
          expect(target_metric[:alert_path]).to include(
            project.path,
            persisted_metric.id.to_s,
            environment.id.to_s
          )
        end
      end

      context 'that are shared across projects' do
        let!(:persisted_metric) { create(:prometheus_metric, :common, identifier: 'metric_a1') }

        it_behaves_like 'has saved alerts'
      end

      context 'when the project has associated metrics' do
        let!(:persisted_metric) { create(:prometheus_metric, project: project, group: :business) }

        it_behaves_like 'has saved alerts'
      end
    end

    context 'when there are no alerts' do
      let!(:persisted_metric) { create(:prometheus_metric, :common, identifier: 'metric_a1') }

      it 'does not insert an alert_path' do
        target_metric = all_metrics.find { |metric| metric[:metric_id] == persisted_metric.id }

        expect(target_metric).to be_a Hash
        expect(target_metric).not_to include(:alert_path)
      end
    end
  end

  private

  def all_metrics
    dashboard[:panel_groups].flat_map do |group|
      group[:panels].flat_map { |panel| panel[:metrics] }
    end
  end
end
