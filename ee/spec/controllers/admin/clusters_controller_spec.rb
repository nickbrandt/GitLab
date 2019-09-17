# frozen_string_literal: true

require 'spec_helper'

describe Admin::ClustersController do
  it_behaves_like 'cluster metrics' do
    let(:user) { create(:admin) }
    let(:clusterable) { Clusters::Instance.new }

    let(:cluster) do
      create(:cluster, :instance, :provided_by_gcp)
    end

    let(:metrics_params) do
      {
        id: cluster
      }
    end

    before do
      allow(::Clusters::Instance).to receive(:new).and_return(cluster.instance)
    end

    context 'with inappropriate requests' do
      context 'with anoymous user' do
        before do
          sign_out(user)
        end

        it 'renders not found' do
          get :prometheus_proxy, params: prometheus_proxy_params

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'with non-admin user' do
        let(:user) { create(:user) }

        before do
          sign_in(user)
        end

        it 'renders not found' do
          get :prometheus_proxy, params: prometheus_proxy_params

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    describe 'GET #metrics_dashboard' do
      let(:user) { create(:admin) }

      before do
        sign_in(user)
      end

      it_behaves_like 'the default dashboard'
    end
  end

  private

  def prometheus_proxy_params(params = {})
    {
      id: cluster.id.to_s,
      proxy_path: 'query',
      query: '1'
    }.merge(params)
  end
end
