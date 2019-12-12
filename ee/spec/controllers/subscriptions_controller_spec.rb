# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionsController do
  let_it_be(:user) { create(:user) }

  describe 'GET #new' do
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

  describe 'GET #payment_form' do
    subject { get :payment_form, params: { id: 'cc' } }

    context 'with unauthorized user' do
      it { is_expected.to have_gitlab_http_status 302 }
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with authorized user' do
      before do
        sign_in(user)
        client_response = { success: true, data: { signature: 'x', token: 'y' } }
        allow(Gitlab::SubscriptionPortal::Client).to receive(:payment_form_params).with('cc').and_return(client_response)
      end

      it { is_expected.to have_gitlab_http_status 200 }

      it 'returns the data attribute of the client response in JSON format' do
        subject
        expect(response.body).to eq('{"signature":"x","token":"y"}')
      end
    end
  end

  describe 'GET #payment_method' do
    subject { get :payment_method, params: { id: 'xx' } }

    context 'with unauthorized user' do
      it { is_expected.to have_gitlab_http_status 302 }
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with authorized user' do
      before do
        sign_in(user)
        client_response = { success: true, data: { credit_card_type: 'Visa' } }
        allow(Gitlab::SubscriptionPortal::Client).to receive(:payment_method).with('xx').and_return(client_response)
      end

      it { is_expected.to have_gitlab_http_status 200 }

      it 'returns the data attribute of the client response in JSON format' do
        subject
        expect(response.body).to eq('{"credit_card_type":"Visa"}')
      end
    end
  end
end
