require 'spec_helper'

describe TrialRegistrationsController do

  describe '#create' do
    before do
      stub_feature_flags(invisible_captcha: false)
      stub_application_setting(send_user_confirmation_email: true)
    end

    let(:user_params) do
      {
        name: 'John Doe',
        email: 'johnd2019@local.dev',
        username: 'johnd',
        password: 'abcd1234'
      }
    end

    context 'with skip_confirmation' do
      it 'creates the account as confirmed' do
        post :create, params: { user: user_params.merge(skip_confirmation: true) }

        expect(User.last).to be_confirmed
      end
    end

    context 'without skip_confirmation' do
      it 'creates the account with pending confirmation' do
        post :create, params: { user: user_params }

        expect(User.last).not_to be_confirmed
      end
    end
  end
end
