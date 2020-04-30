# frozen_string_literal: true

require 'spec_helper'

describe RegistrationsController do
  describe '#create' do
    context 'when the user opted-in' do
      let(:user_params) { { user: attributes_for(:user, email_opted_in: '1') } }

      it 'sets the rest of the email_opted_in fields' do
        post :create, params: user_params
        user = User.find_by_username!(user_params[:user][:username])
        expect(user.email_opted_in).to be_truthy
        expect(user.email_opted_in_ip).to be_present
        expect(user.email_opted_in_source).to eq('GitLab.com')
        expect(user.email_opted_in_at).not_to be_nil
      end
    end

    context 'when the user opted-out' do
      let(:user_params) { { user: attributes_for(:user, email_opted_in: '0') } }

      it 'does not set the rest of the email_opted_in fields' do
        post :create, params: user_params
        user = User.find_by_username!(user_params[:user][:username])
        expect(user.email_opted_in).to be_falsey
        expect(user.email_opted_in_ip).to be_blank
        expect(user.email_opted_in_source).to be_blank
        expect(user.email_opted_in_at).to be_nil
      end
    end

    context 'when reCAPTCHA experiment enabled' do
      it "logs a 'User Created' message including the experiment state" do
        user_params = { user: attributes_for(:user) }
        allow_any_instance_of(EE::RecaptchaExperimentHelper).to receive(:show_recaptcha_sign_up?).and_return(true)

        expect(Gitlab::AppLogger).to receive(:info).with(/\AUser Created: .+experiment_growth_recaptcha\?true\z/).and_call_original

        post :create, params: user_params
      end
    end
  end

  describe '#welcome' do
    subject { get :welcome }

    before do
      sign_in(create(:user))
    end

    it 'renders the checkout layout' do
      expect(subject).to render_template(:checkout)
    end
  end
end
