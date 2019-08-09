# frozen_string_literal: true

require 'spec_helper'

describe Clusters::EnvironmentEntity do
  set(:user) { create(:user) }
  set(:group) { create(:group) }
  set(:project) { create(:project, group: group) }
  set(:cluster) { create(:cluster_for_group, groups: [group]) }

  it 'inherits from API::Entities::EnvironmentBasic' do
    expect(described_class).to be < API::Entities::EnvironmentBasic
  end

  describe '#as_json' do
    let(:environment) { create(:environment, project: project) }
    let(:request) { double('request', current_user: user, cluster: cluster) }

    before do
      group.add_maintainer(user)
    end

    subject { described_class.new(environment, request: request).as_json }

    it 'exposes project' do
      expect(subject).to include(:project)
    end

    it 'exposes last_deployment' do
      expect(subject).to include(:last_deployment)
    end

    it 'exposes environment_path' do
      expect(subject).to include(:environment_path)
    end

    context 'deploy board available' do
      before do
        allow(group).to receive(:feature_available?).and_call_original
        allow(group).to receive(:feature_available?).with(:cluster_deployments).and_return(true)
      end

      it 'exposes rollout_status' do
        expect(subject).to include(:rollout_status)
      end
    end

    context 'deploy board not available' do
      before do
        allow(group).to receive(:feature_available?).with(:cluster_deployments).and_return(false)
      end

      it 'does not expose rollout_status' do
        expect(subject).not_to include(:rollout_status)
      end
    end
  end
end
