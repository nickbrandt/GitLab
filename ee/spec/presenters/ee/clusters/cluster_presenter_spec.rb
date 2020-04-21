# frozen_string_literal: true

require 'spec_helper'

describe Clusters::ClusterPresenter do
  include Gitlab::Routing.url_helpers

  describe '#health_data' do
    shared_examples 'cluster health data' do
      let(:user) { create(:user) }
      let(:cluster_presenter) { cluster.present(current_user: user) }

      let(:clusterable_presenter) do
        ClusterablePresenter.fabricate(clusterable, current_user: user)
      end

      subject { cluster_presenter.health_data(clusterable_presenter) }

      it do
        is_expected.to match(
          'clusters-path': clusterable_presenter.index_path,
          'metrics-endpoint': clusterable_presenter.metrics_cluster_path(cluster, format: :json),
          'dashboard-endpoint': clusterable_presenter.metrics_dashboard_path(cluster),
          'documentation-path': help_page_path('user/project/clusters/index', anchor: 'monitoring-your-kubernetes-cluster-ultimate'),
          'empty-getting-started-svg-path': match_asset_path('/assets/illustrations/monitoring/getting_started.svg'),
          'empty-loading-svg-path': match_asset_path('/assets/illustrations/monitoring/loading.svg'),
          'empty-no-data-svg-path': match_asset_path('/assets/illustrations/monitoring/no_data.svg'),
          'empty-unable-to-connect-svg-path': match_asset_path('/assets/illustrations/monitoring/unable_to_connect.svg'),
          'settings-path': '',
          'project-path': '',
          'tags-path': '',
          'alerts-endpoint': '/',
          'prometheus-alerts-available': 'true'
        )
      end

      context 'when prometheus_computed_alerts feature is disabled' do
        before do
          stub_feature_flags(prometheus_computed_alerts: false)
        end

        it 'alerts-endpoint is nil' do
          expect(subject['alerts-endpoint']).to be_nil
        end

        it 'prometheus-alerts-available is nil' do
          expect(subject['prometheus-alerts-available']).to be_nil
        end
      end
    end

    context 'with project cluster' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:clusterable) { cluster.project }

      it_behaves_like 'cluster health data'
    end

    context 'with group cluster' do
      let(:cluster) { create(:cluster, :group, :provided_by_gcp) }
      let(:clusterable) { cluster.group }

      it_behaves_like 'cluster health data'
    end
  end
end
