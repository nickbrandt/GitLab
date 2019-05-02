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

    it 'contains all keys' do
      expect(subject).to include(
        'settings-path' => edit_project_service_path(project, 'prometheus'),
        'clusters-path' => project_clusters_path(project),
        'current-environment-name': environment.name,
        'documentation-path' => help_page_path('administration/monitoring/prometheus/index.md'),
        'empty-getting-started-svg-path' => match_asset_path('/assets/illustrations/monitoring/getting_started.svg'),
        'empty-loading-svg-path' => match_asset_path('/assets/illustrations/monitoring/loading.svg'),
        'empty-no-data-svg-path' => match_asset_path('/assets/illustrations/monitoring/no_data.svg'),
        'empty-unable-to-connect-svg-path' => match_asset_path('/assets/illustrations/monitoring/unable_to_connect.svg'),
        'metrics-endpoint' => additional_metrics_project_environment_path(project, environment, format: :json),
        'deployment-endpoint' => project_environment_deployments_path(project, environment, format: :json),
        'environments-endpoint': project_environments_path(project, format: :json),
        'project-path' => project_path(project),
        'tags-path' => project_tags_path(project),
        'has-metrics' => "#{environment.has_metrics?}",
        'custom-metrics-path' => project_prometheus_metrics_path(project),
        'validate-query-path' => validate_query_project_prometheus_metrics_path(project),
        'custom-metrics-available' => 'false',
        'alerts-endpoint' => project_prometheus_alerts_path(project, environment_id: environment.id, format: :json),
        'prometheus-alerts-available' => 'true'
      )

      expect(subject.keys).to contain_exactly(
        'settings-path', 'clusters-path', :'current-environment-name', 'documentation-path',
        'empty-getting-started-svg-path', 'empty-loading-svg-path', 'empty-no-data-svg-path',
        'empty-unable-to-connect-svg-path', 'metrics-endpoint', 'deployment-endpoint',
        :'environments-endpoint', 'project-path', 'tags-path', 'has-metrics', 'custom-metrics-path',
        'validate-query-path', 'custom-metrics-available', 'alerts-endpoint', 'prometheus-alerts-available'
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
