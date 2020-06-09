# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController do
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

  describe '#update_registration' do
    before do
      sign_in(create(:user))
    end

    subject(:update_registration) { patch :update_registration, params: { user: { role: 'software_developer', setup_for_company: 'false' } } }

    it { is_expected.to redirect_to dashboard_projects_path }

    context 'when part of the onboarding issues experiment' do
      before do
        stub_experiment_for_user(onboarding_issues: true)
      end

      it { is_expected.to redirect_to new_users_sign_up_group_path }

      context 'when in subscription flow' do
        before do
          allow(controller.helpers).to receive(:in_subscription_flow?).and_return(true)
        end

        it { is_expected.not_to redirect_to new_users_sign_up_group_path }
      end

      context 'when in invitation flow' do
        before do
          allow(controller.helpers).to receive(:in_invitation_flow?).and_return(true)
        end

        it { is_expected.not_to redirect_to new_users_sign_up_group_path }
      end
    end

    describe 'tracking for the onboarding issues experiment' do
      using RSpec::Parameterized::TableSyntax

      where(:on_gitlab_com, :experiment_enabled, :in_subscription_flow, :in_invitation_flow, :experiment_enabled_for_user, :expected_tracking) do
        false | false | false | false | true  | nil
        false | false | false | true  | true  | nil
        false | false | true  | false | true  | nil
        false | false | true  | true  | true  | nil
        false | true  | false | false | true  | nil
        false | true  | false | true  | true  | nil
        false | true  | true  | false | true  | nil
        false | true  | true  | true  | true  | nil
        true  | false | false | false | true  | nil
        true  | false | false | true  | true  | nil
        true  | false | true  | false | true  | nil
        true  | false | true  | true  | true  | nil
        true  | true  | false | false | true  | 'experimental_group'
        true  | true  | false | false | false | 'control_group'
        true  | true  | false | true  | true  | nil
        true  | true  | true  | false | true  | nil
        true  | true  | true  | true  | true  | nil
      end

      with_them do
        before do
          allow(::Gitlab).to receive(:com?).and_return(on_gitlab_com)
          stub_experiment(onboarding_issues: experiment_enabled)
          allow(controller.helpers).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
          allow(controller.helpers).to receive(:in_invitation_flow?).and_return(in_invitation_flow)
          stub_experiment_for_user(onboarding_issues: experiment_enabled_for_user)
        end

        it 'tracks when appropriate' do
          if expected_tracking
            expect(Gitlab::Tracking).to receive(:event).with(
              'Growth::Conversion::Experiment::OnboardingIssues',
              'signed_up',
              label: anything,
              property: expected_tracking
            )
          else
            expect(Gitlab::Tracking).not_to receive(:event)
          end

          update_registration
        end
      end
    end
  end
end
