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
end
