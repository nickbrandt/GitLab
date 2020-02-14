# frozen_string_literal: true

require 'spec_helper'

describe Projects::ClustersController do
  let_it_be(:project) { create(:project) }

  it_behaves_like 'cluster metrics' do
    let(:user) { create(:user) }
    let(:clusterable) { project }

    let(:cluster) do
      create(:cluster, :project, :provided_by_gcp, projects: [project])
    end

    let(:metrics_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: cluster
      }
    end

    before do
      clusterable.add_maintainer(user)
    end

    context 'with inappropriate requests' do
      context 'with annoymous user' do
        before do
          sign_out(user)
        end

        it 'redirects to signin page' do
          get :prometheus_proxy, params: prometheus_proxy_params

          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'with invalid clusterable id' do
        before do
          sign_in(user)
        end

        let(:other_clusterable) { create(:project) }

        it 'returns 404' do
          get :prometheus_proxy, params: prometheus_proxy_params(id: other_clusterable.id)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'security' do
      let(:prometheus_adapter) { double(:prometheus_adapter, can_query?: true, query: nil) }

      before do
        sign_in(user)
        allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
      end

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(clusterable) }
      it { expect { go }.to be_allowed_for(:maintainer).of(clusterable) }
      it { expect { go }.to be_denied_for(:developer).of(clusterable) }
      it { expect { go }.to be_denied_for(:reporter).of(clusterable) }
      it { expect { go }.to be_denied_for(:guest).of(clusterable) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end

    describe 'GET #metrics_dashboard' do
      let(:user) { create(:user) }

      before do
        clusterable.add_maintainer(user)
        sign_in(user)
      end

      it_behaves_like 'the default dashboard'
    end
  end

  private

  def prometheus_proxy_params(params = {})
    {
      id: cluster.id.to_s,
      namespace_id: project.namespace.full_path,
      project_id: project.name,
      proxy_path: 'query',
      query: '1'
    }.merge(params)
  end
end
