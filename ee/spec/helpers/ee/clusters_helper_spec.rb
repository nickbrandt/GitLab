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
end
