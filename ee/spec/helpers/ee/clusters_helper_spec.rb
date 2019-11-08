# frozen_string_literal: true

require 'spec_helper'

describe ClustersHelper do
  shared_examples 'feature availablilty' do |feature|
    before do
      # clusterable is provided as a `helper_method`
      allow(helper).to receive(:clusterable).and_return(clusterable)

      expect(clusterable)
        .to receive(:feature_available?)
        .with(feature)
        .and_return(feature_available)
    end

    context 'feature unavailable' do
      let(:feature_available) { true }

      it { is_expected.to be_truthy }
    end

    context 'feature available' do
      let(:feature_available) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_multiple_clusters?' do
    subject { helper.has_multiple_clusters? }

    context 'project level' do
      let(:clusterable) { instance_double(Project) }

      it_behaves_like 'feature availablilty', :multiple_clusters
    end

    context 'group level' do
      let(:clusterable) { instance_double(Group) }

      it_behaves_like 'feature availablilty', :multiple_clusters
    end
  end

  describe '#show_cluster_health_graphs?' do
    subject { helper.show_cluster_health_graphs? }

    context 'project level' do
      let(:clusterable) { instance_double(Project) }

      it_behaves_like 'feature availablilty', :cluster_health
    end

    context 'group level' do
      let(:clusterable) { instance_double(Group) }

      it_behaves_like 'feature availablilty', :cluster_health
    end
  end

  describe '#cluster_health_data' do
    shared_examples 'cluster health data' do
      let(:user) { create(:user) }
      let(:cluster_presenter) { cluster.present(current_user: user) }

      let(:clusterable_presenter) do
        ClusterablePresenter.fabricate(clusterable, current_user: user)
      end

      subject { helper.cluster_health_data(cluster_presenter) }

      before do
        allow(helper).to receive(:clusterable).and_return(clusterable_presenter)
      end

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
          'tags-path': ''
        )
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
