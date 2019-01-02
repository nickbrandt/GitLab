# frozen_string_literal: true

require 'spec_helper'

shared_examples 'ee clusterable policies' do
  describe '#can_add_cluster?' do
    let(:current_user) { create(:user) }

    subject { described_class.new(current_user, clusterable) }

    before do
      clusterable.add_maintainer(current_user)
    end

    context 'when multiple_clusters feature is available' do
      before do
        stub_licensed_features(multiple_clusters: true)
      end

      context 'when clusterable has clusters' do
        before do
          cluster
        end

        it { is_expected.to be_allowed(:add_cluster) }
      end

      context 'when clusterable does not have clusters' do
        it { is_expected.to be_allowed(:add_cluster) }
      end
    end

    context 'when multiple_clusters feature is not available' do
      before do
        stub_licensed_features(multiple_clusters: false)
      end

      context 'when clusterable has clusters' do
        before do
          cluster
        end

        it { is_expected.to be_disallowed(:add_cluster) }
      end

      context 'when clusterable does not have clusters' do
        it { is_expected.to be_allowed(:add_cluster) }
      end
    end
  end
end
