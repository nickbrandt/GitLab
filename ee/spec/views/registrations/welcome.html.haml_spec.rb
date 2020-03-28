# frozen_string_literal: true

require 'spec_helper'

describe 'registrations/welcome' do
  let_it_be(:user) { User.new }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
    allow(view).to receive(:in_trial_flow?).and_return(in_trial_flow)

    render
  end

  subject { rendered }

  context 'in subscription flow' do
    let(:in_subscription_flow) { true }
    let(:in_trial_flow) { false }

    it { is_expected.to have_button('Continue') }
    it { is_expected.to have_selector('#progress-bar') }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: 'Who will be using this GitLab subscription?') }
  end

  context 'in trial flow' do
    let(:in_subscription_flow) { false }
    let(:in_trial_flow) { true }

    it { is_expected.to have_button('Continue') }
    it { is_expected.not_to have_selector('#progress-bar') }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: 'Who will be using this GitLab trial?') }
  end

  context 'neither in subscription nor in trial flow' do
    let(:in_subscription_flow) { false }
    let(:in_trial_flow) { false }

    it { is_expected.to have_button('Get started!') }
    it { is_expected.not_to have_selector('#progress-bar') }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: 'Who will be using GitLab?') }
  end
end
