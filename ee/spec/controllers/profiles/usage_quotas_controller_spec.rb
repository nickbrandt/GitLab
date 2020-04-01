# frozen_string_literal: true

require 'spec_helper'

describe Profiles::UsageQuotasController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    context 'when feature flag user_usage_quota is disabled' do
      before do
        stub_feature_flags(user_usage_quota: false)
      end

      it 'redirects to pipeline quota page' do
        get :index

        expect(subject).to redirect_to(profile_pipeline_quota_path)
      end
    end

    context 'when feature flag user_usage_quota is enabled' do
      it 'renders usage quota page' do
        get :index

        expect(subject).to render_template(:index)
      end
    end
  end
end
