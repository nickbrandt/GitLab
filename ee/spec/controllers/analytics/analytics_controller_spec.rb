# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::AnalyticsController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it 'renders devops score page when all the analytics feature flags are disabled' do
      get :index

      expect(response).to redirect_to(instance_statistics_dev_ops_score_index_path)
    end

    context 'when instance statistics is private' do
      before do
        stub_application_setting(instance_statistics_visibility_private: true)
      end

      it 'renders 404, not found' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
