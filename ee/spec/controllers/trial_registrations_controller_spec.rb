# frozen_string_literal: true

require 'spec_helper'

describe TrialRegistrationsController do
  describe '#new' do
    let(:user) { create(:user) }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    context 'when feature is turned off' do
      before do
        stub_feature_flags(improved_trial_signup: false)
      end

      it 'redirects to subscription portal trial url' do
        get :new

        expect(response).to redirect_to("#{EE::SUBSCRIPTIONS_URL}/trials/new?gl_com=true")
      end
    end

    context 'when customer is authenticated' do
      before do
        sign_in(user)
      end

      it 'redirects to the new trial page' do
        get :new

        expect(response).to redirect_to(new_trial_url)
      end
    end

    context 'when customer is not authenticated' do
      it 'renders the regular template' do
        get :new

        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    before do
      stub_application_setting(send_user_confirmation_email: true)
    end

    let(:user_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email: 'johnd2019@local.dev',
        username: 'johnd',
        password: 'abcd1234'
      }
    end

    context 'when invalid - instance is not GL.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'returns 404 not found' do
        post :create, params: { user: user_params }

        expect(response.status).to eq(404)
      end
    end

    context 'when feature is turned off' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_feature_flags(improved_trial_signup: false)
      end

      it 'returns not found' do
        post :create, params: { user: user_params }

        expect(response).to redirect_to("#{EE::SUBSCRIPTIONS_URL}/trials/new?gl_com=true")
      end
    end

    context 'when valid' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'marks the account as confirmed' do
        post :create, params: { user: user_params }

        expect(User.last).to be_confirmed
      end

      context 'derivation of name' do
        it 'sets name from first and last name' do
          post :create, params: { user: user_params }

          expect(User.last.name).to eq("#{user_params[:first_name]} #{user_params[:last_name]}")
        end
      end
    end
  end
end
