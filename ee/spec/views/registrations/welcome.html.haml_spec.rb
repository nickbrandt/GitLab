# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome' do
  let_it_be(:user) { User.new }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
    allow(view).to receive(:in_trial_flow?).and_return(in_trial_flow)
    allow(view).to receive(:in_invitation_flow?).and_return(in_invitation_flow)
    allow(view).to receive(:experiment_enabled?).with(:onboarding_issues).and_return(onboarding_issues_experiment_enabled)

    render
  end

  subject { rendered }

  context 'in subscription flow' do
    let(:in_subscription_flow) { true }
    let(:in_trial_flow) { false }
    let(:in_invitation_flow) { false }
    let(:onboarding_issues_experiment_enabled) { false }

    it { is_expected.to have_button('Continue') }
    it { is_expected.to have_selector('#progress-bar') }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: 'Who will be using this GitLab subscription?') }
  end

  context 'in trial flow' do
    let(:in_subscription_flow) { false }
    let(:in_trial_flow) { true }
    let(:in_invitation_flow) { false }
    let(:onboarding_issues_experiment_enabled) { false }

    it { is_expected.to have_button('Continue') }
    it { is_expected.not_to have_selector('#progress-bar') }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: 'Who will be using this GitLab trial?') }
  end

  context 'when onboarding issues experiment is enabled' do
    let(:in_subscription_flow) { false }
    let(:in_trial_flow) { false }
    let(:in_invitation_flow) { false }
    let(:onboarding_issues_experiment_enabled) { true }

    it { is_expected.to have_button('Continue') }
    it { is_expected.to have_selector('#progress-bar') }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: 'Who will be using GitLab?') }

    context 'when in invitation flow' do
      let(:in_invitation_flow) { true }

      it { is_expected.to have_button('Get started!') }
      it { is_expected.not_to have_selector('#progress-bar') }
    end
  end

  context 'when neither in subscription nor in trial flow and onboarding issues experiment is disabled' do
    let(:in_subscription_flow) { false }
    let(:in_trial_flow) { false }
    let(:in_invitation_flow) { false }
    let(:onboarding_issues_experiment_enabled) { false }

    it { is_expected.to have_button('Get started!') }
    it { is_expected.not_to have_selector('#progress-bar') }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: 'Who will be using GitLab?') }
  end
end
