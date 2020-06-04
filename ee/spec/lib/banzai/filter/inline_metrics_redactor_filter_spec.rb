# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineMetricsRedactorFilter do
  include FilterSpecHelper

  let_it_be(:project) { create(:project) }
  let(:input) { %(<div class="js-render-metrics" data-dashboard-url="#{url}"></div>) }
  let(:doc) { filter(input) }

  context 'for an alert embed' do
    let_it_be(:alert) { create(:prometheus_alert, project: project) }
    let(:url) do
      urls.metrics_dashboard_project_prometheus_alert_url(
        project,
        alert.prometheus_metric_id,
        environment_id: alert.environment_id,
        embedded: true
      )
    end

    before do
      stub_licensed_features(prometheus_alerts: true)
    end

    it_behaves_like 'redacts the embed placeholder'
    it_behaves_like 'retains the embed placeholder when applicable'
  end

  context 'for a cluster metric embed' do
    let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [project]) }
    let(:params) { [project.namespace.path, project.path, cluster.id] }
    let(:query_params) { { group: 'Cluster Health', title: 'CPU Usage', y_label: 'CPU (cores)' } }
    let(:url) { urls.metrics_namespace_project_cluster_url(*params, **query_params) }

    context 'with cluster health license' do
      before do
        stub_licensed_features(cluster_health: true)
      end

      it_behaves_like 'redacts the embed placeholder'
      it_behaves_like 'retains the embed placeholder when applicable'
    end

    context 'without cluster health license' do
      let(:doc) { filter(input, current_user: project.owner) }

      before do
        stub_licensed_features(cluster_health: false)
      end

      it 'redacts the embed placeholder' do
        expect(doc.to_s).to be_empty
      end
    end
  end
end
