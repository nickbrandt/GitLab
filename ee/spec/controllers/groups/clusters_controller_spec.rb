# frozen_string_literal: true

require 'spec_helper'

describe Groups::ClustersController do
  set(:group) { create(:group) }

  it_behaves_like 'cluster metrics' do
    let(:clusterable) { group }

    let(:cluster) do
      create(:cluster, :group, :provided_by_gcp, groups: [group])
    end

    let(:metrics_params) do
      {
        group_id: group,
        id: cluster
      }
    end
  end
end
