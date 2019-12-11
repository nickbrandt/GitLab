# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentsHelper do
  let(:environment) { create(:environment) }
  let(:project) { environment.project }
  let(:user) { create(:user) }

  describe '#metrics_data' do
    subject { helper.metrics_data(project, environment) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?)
        .with(user, :read_prometheus_alerts, project)
        .and_return(true)
      allow(helper).to receive(:can?)
        .with(user, :admin_project, project)
        .and_return(true)
    end

    it 'returns additional configuration' do
      expect(subject).to include(
        'custom-metrics-path' => project_prometheus_metrics_path(project),
        'validate-query-path' => validate_query_project_prometheus_metrics_path(project),
        'custom-metrics-available' => 'false',
        'alerts-endpoint' => project_prometheus_alerts_path(project, environment_id: environment.id, format: :json),
        'prometheus-alerts-available' => 'true'
      )
    end
  end

  describe '#environment_logs_data' do
    subject { helper.environment_logs_data(project, environment) }

    it 'returns environment parameters data' do
      expect(subject).to include(
        "environment-name": environment.name,
        "environments-path": project_environments_path(project, format: :json)
      )
    end

    it 'returns parameters for forming the pod logs API URL' do
      expect(subject).to include(
        "project-full-path": project.full_path,
        "environment-id": environment.id
      )
    end
  end

  describe '#custom_metrics_available?' do
    subject { helper.custom_metrics_available?(project) }

    before do
      project.add_maintainer(user)

      stub_licensed_features(custom_prometheus_metrics: true)

      allow(helper).to receive(:current_user).and_return(user)

      allow(helper).to receive(:can?)
        .with(user, :admin_project, project)
        .and_return(true)
    end

    it 'returns true' do
      expect(subject).to eq(true)
    end
  end
end
