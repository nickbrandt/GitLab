# frozen_string_literal: true

require 'spec_helper'

describe ClustersHelper do
  describe '#has_multiple_clusters?' do
    let(:project) { build(:project) }

    subject { helper.has_multiple_clusters? }

    before do
      # clusterable is provided as a `helper_method`
      allow(helper).to receive(:clusterable).and_return(project)
    end

    context 'license is premium' do
      before do
        expect(project).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
      end

      it { is_expected.to be_truthy }
    end

    context 'license is starter' do
      before do
        expect(project).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#show_cluster_health_graphs?' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:cluster_presenter) { cluster.present }

    before do
      stub_licensed_features(cluster_health: true)
    end

    context 'with project level cluster' do
      it 'returns true' do
        expect(helper.show_cluster_health_graphs?(cluster_presenter)).to eq(true)
      end
    end

    context 'with group level cluster' do
      let(:cluster) { create(:cluster, :group, :provided_by_gcp) }

      it 'returns false' do
        expect(helper.show_cluster_health_graphs?(cluster_presenter)).to eq(false)
      end
    end

    context 'without cluster_health license' do
      before do
        stub_licensed_features(cluster_health: false)
      end

      it 'returns false' do
        expect(helper.show_cluster_health_graphs?(cluster_presenter)).to eq(false)
      end
    end
  end

  describe '#cluster_health_data' do
    let(:project) { cluster.project }
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:cluster_presenter) { cluster.present }

    it 'returns graph configuration' do
      expect(cluster_health_data(cluster_presenter)).to eq(
        'clusters-path': project_clusters_path(project),
        'documentation-path': help_page_path('administration/monitoring/prometheus/index.md'),
        'empty-getting-started-svg-path': image_path('illustrations/monitoring/getting_started.svg'),
        'empty-loading-svg-path': image_path('illustrations/monitoring/loading.svg'),
        'empty-no-data-svg-path': image_path('illustrations/monitoring/no_data.svg'),
        'empty-unable-to-connect-svg-path': image_path('illustrations/monitoring/unable_to_connect.svg'),
        'metrics-endpoint': metrics_project_cluster_path(project, cluster, format: :json),
        'settings-path': '',
        'project-path': '',
        'tags-path': ''
      )
    end
  end
end
