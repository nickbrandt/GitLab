# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertNotificationsController do
  set(:project) { create(:project) }
  set(:environment) { create(:environment, project: project) }

  describe 'POST #create' do
    it 'returns ok' do
      post :create, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
