# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertNotificationsController do
  set(:project) { create(:project) }
  set(:environment) { create(:environment, project: project) }

  describe 'POST #create' do
    def make_request(opts = {})
      post :create, params: project_params, session: { as: :json }
    end

    context 'when feature flag is on' do
      before do
        stub_feature_flags(generic_alert_endpoint: true)
      end

      it 'responds with ok' do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when feature flag is off' do
      before do
        stub_feature_flags(generic_alert_endpoint: false)
      end

      it 'responds with not_found' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
