# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionsController do
  let_it_be(:user) { create(:user) }

  describe 'GET #new' do
    subject { get :new, params: { plan_id: 'bronze_id' } }

    context 'with experiment enabled' do
      before do
        stub_experiment(paid_signup_flow: true)
        stub_experiment_for_user(paid_signup_flow: true)
      end

      context 'with unauthorized user' do
        it { is_expected.to have_gitlab_http_status 302 }
        it { is_expected.to redirect_to new_user_registration_path }

        it 'stores subscription URL for later' do
          subject

          expect(controller.stored_location_for(:user)).to eq(new_subscriptions_path(plan_id: 'bronze_id'))
        end
      end

      context 'with authorized user' do
        before do
          sign_in(user)
        end

        it { is_expected.to render_template 'layouts/checkout' }
        it { is_expected.to render_template :new }
      end
    end

    context 'with experiment disabled' do
      before do
        stub_experiment(paid_signup_flow: false)
        stub_experiment_for_user(paid_signup_flow: false)
      end

      it { is_expected.to redirect_to "#{EE::SUBSCRIPTIONS_URL}/subscriptions/new?plan_id=bronze_id&transaction=create_subscription" }
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
