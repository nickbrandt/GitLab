# frozen_string_literal: true

require 'spec_helper'

describe GroupClusterablePresenter do
  include Gitlab::Routing.url_helpers

  let(:presenter) { described_class.new(group) }
  let(:cluster) { create(:cluster, :provided_by_gcp, :group) }
  let(:group) { cluster.group }

  describe '#metrics_cluster_path' do
    subject { presenter.metrics_cluster_path(cluster) }

    it { is_expected.to eq(metrics_group_cluster_path(group, cluster)) }
  end
end
