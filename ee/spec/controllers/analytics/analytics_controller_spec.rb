# frozen_string_literal: true

require 'spec_helper'

describe Analytics::AnalyticsController do
  include AnalyticsHelpers

  let(:user) { create(:user) }

  before do
    stub_feature_flags(group_level_cycle_analytics: false)

    sign_in(user)
    disable_all_analytics_feature_flags
  end

  describe 'GET index' do
    describe 'redirects to the first enabled analytics page' do
      it 'redirects to value stream analytics' do
        stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)

        get :index

        expect(response).to redirect_to(analytics_cycle_analytics_path)
      end
    end

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
