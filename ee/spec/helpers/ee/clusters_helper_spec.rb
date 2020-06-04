# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClustersHelper do
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
end
