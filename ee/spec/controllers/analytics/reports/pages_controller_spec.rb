# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Reports::PagesController do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    stub_licensed_features(group_activity_analytics: true)
    stub_feature_flags(Gitlab::Analytics::REPORT_PAGES_FEATURE_FLAG => true)
  end

  describe 'GET show' do
    it 'renders the report page' do
      get :show

      expect(response).to render_template :show
    end

    context 'when the feature flag is false' do
      before do
        stub_feature_flags(Gitlab::Analytics::REPORT_PAGES_FEATURE_FLAG => false)
      end

      it 'renders 404, not found' do
        get :show

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(group_activity_analytics: false)
      end

      it 'renders 404, not found' do
        get :show

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
