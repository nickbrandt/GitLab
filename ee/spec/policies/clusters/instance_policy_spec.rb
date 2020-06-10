# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::InstancePolicy, :enable_admin_mode do
  let(:user) { build(:admin) }
  let(:instance) { Clusters::Instance.new }

  subject { described_class.new(user, instance) }

  context 'when cluster deployments is available' do
    before do
      stub_licensed_features(cluster_deployments: true)
    end

    it { is_expected.to be_allowed(:read_cluster_environments) }
  end

  context 'when cluster deployments is unavailable' do
    before do
      stub_licensed_features(cluster_deployments: false)
    end

    it { is_expected.not_to be_allowed(:read_cluster_environments) }
  end

  context 'when cluster is readable' do
    context 'and cluster health is available' do
      before do
        stub_licensed_features(cluster_health: true)
      end

      it { is_expected.to be_allowed(:read_cluster_health) }
    end

    context 'and cluster health is unavailable' do
      before do
        stub_licensed_features(cluster_health: false)
      end

      it { is_expected.to be_disallowed(:read_cluster_health) }
    end
  end

  context 'when cluster is not readable to user' do
    let(:user) { build(:user) }

    context 'when cluster health is available' do
      before do
        stub_licensed_features(cluster_health: true)
      end

      it { is_expected.to be_disallowed(:read_cluster_health) }
    end

    context 'when cluster health is unavailable' do
      before do
        stub_licensed_features(cluster_health: false)
      end

      it { is_expected.to be_disallowed(:read_cluster_health) }
    end
  end
end
