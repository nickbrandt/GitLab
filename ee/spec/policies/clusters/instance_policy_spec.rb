# frozen_string_literal: true

require 'spec_helper'

describe Clusters::InstancePolicy do
  let(:user) { create(:admin) }

  subject { described_class.new(user, Clusters::Instance.new) }

  context 'when cluster deployments is available' do
    before do
      stub_licensed_features(cluster_deployments: true)
    end

    it { is_expected.to be_allowed(:read_cluster_environments) }
  end

  context 'when cluster deployments is not available' do
    before do
      stub_licensed_features(cluster_deployments: false)
    end

    it { is_expected.not_to be_allowed(:read_cluster_environments) }
  end
end
