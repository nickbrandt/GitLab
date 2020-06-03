# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupClusters do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_maintainer(current_user)
  end

  describe 'POST /groups/:id/clusters/user' do
    let(:api_url) { 'https://kubernetes.example.com' }

    let(:platform_kubernetes_attributes) do
      {
        api_url: api_url,
        token: 'sample-token'
      }
    end

    let(:cluster_params) do
      {
        name: 'test-cluster',
        environment_scope: 'production/*',
        platform_kubernetes_attributes: platform_kubernetes_attributes
      }
    end

    context 'when user sets specific environment scope' do
      it 'creates a cluster with that specific environment' do
        post api("/groups/#{group.id}/clusters/user", current_user), params: cluster_params

        expect(json_response['environment_scope']).to eq('production/*')
      end
    end

    context 'when does not set an specific environment scope' do
      let(:cluster_params) do
        {
          name: 'test-cluster',
          platform_kubernetes_attributes: platform_kubernetes_attributes
        }
      end

      it 'sets default environment' do
        post api("/groups/#{group.id}/clusters/user", current_user), params: cluster_params

        expect(json_response['environment_scope']).to eq('*')
      end
    end

    context 'when license has multiple clusters feature' do
      before do
        stub_licensed_features(multiple_clusters: true)

        create(:cluster, :provided_by_gcp, :group,
               groups: [group])

        post api("/groups/#{group.id}/clusters/user", current_user), params: cluster_params
      end

      it 'responds with 201' do
        expect(response).to have_gitlab_http_status(:created)
      end

      it 'allows multiple clusters to be associated to group' do
        expect(group.reload.clusters.count).to eq(2)
      end
    end
  end

  describe 'PUT /groups/:id/clusters/:cluster_id' do
    let(:api_url) { 'https://kubernetes.example.com' }

    let(:update_params) do
      {
        environment_scope: 'test/*'
      }
    end

    before do
      put api("/groups/#{group.id}/clusters/#{cluster.id}", current_user), params: update_params

      cluster.reload
    end

    context 'With a GCP cluster' do
      let(:cluster) do
        create(:cluster, :group, :provided_by_gcp,
               groups: [group])
      end

      it 'updates the environment scope' do
        expect(cluster.environment_scope).to eq('test/*')
      end
    end

    context 'With an user cluster' do
      let(:cluster) do
        create(:cluster, :group, :provided_by_user,
               groups: [group])
      end

      it 'updates the environment scope' do
        expect(cluster.environment_scope).to eq('test/*')
      end
    end
  end
end
