# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::CreateService do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

  subject { described_class.new(user, params).execute(access_token: access_token) }

  before do
    allow(project).to receive(:feature_available?).and_call_original
  end

  context 'when license has multiple clusters feature' do
    before do
      allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
    end

    context 'when correct params' do
      let(:params) do
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a',
            legacy_abac: 'true'
          },
          clusterable: project
        }
      end

      include_examples 'create cluster service success'
    end

    context 'when invalid params' do
      let(:params) do
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: '!!!!!!!',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          },
          clusterable: project
        }
      end

      include_examples 'create cluster service error'
    end
  end

  context 'when license does not have multiple clusters feature' do
    include_context 'valid cluster create params'

    before do
      allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
    end

    it 'does not create a cluster' do
      expect(ClusterProvisionWorker).not_to receive(:perform_async)
      expect { subject }.to raise_error(ArgumentError).and change { Clusters::Cluster.count }.by(0)
    end
  end
end
