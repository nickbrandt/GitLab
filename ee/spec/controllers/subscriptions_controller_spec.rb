# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionsController do
  describe 'GET #new' do
    let_it_be(:user) { create(:user) }

    subject { get :new, params: { plan_id: 'bronze_id' } }

    context 'with unauthorized user' do
      it { is_expected.to have_gitlab_http_status 302 }
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with authorized user' do
      before do
        sign_in(user)
      end

      context 'with feature flag enabled' do
        before do
          stub_feature_flags(paid_signup_flow: true)
        end

        it { is_expected.to render_template 'layouts/checkout' }
        it { is_expected.to render_template :new }
      end

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(paid_signup_flow: false)
        end

        it { is_expected.to have_gitlab_http_status 302 }
        it { is_expected.to redirect_to dashboard_projects_path }
      end
    end
  end
end
