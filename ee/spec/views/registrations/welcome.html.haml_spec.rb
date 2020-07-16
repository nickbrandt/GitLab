# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { User.new }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
    allow(view).to receive(:in_trial_flow?).and_return(in_trial_flow)
    allow(view).to receive(:in_invitation_flow?).and_return(in_invitation_flow)
    allow(view).to receive(:in_oauth_flow?).and_return(in_oauth_flow)
    allow(view).to receive(:experiment_enabled?).with(:onboarding_issues).and_return(onboarding_issues_experiment_enabled)

    render
  end

  subject { rendered }

  where(:in_subscription_flow, :in_trial_flow, :in_invitation_flow, :in_oauth_flow, :onboarding_issues_experiment_enabled, :flow) do
    false | false | false | false | false | :regular
    true  | false | false | false | false | :subscription
    false | true  | false | false | false | :trial
    false | false | true  | false | false | :invitation
    false | false | false | true  | false | :oauth
    false | false | false | false | true  | :onboarding
    false | false | true  | false | true  | :onboarding_invitation
    false | false | false | true  | true  | :onboarding_oauth
  end

  def button_text
    if %i(subscription trial onboarding).include?(flow)
      'Continue'
    else
      'Get started!'
    end
  end

  def label_text
    if flow == :subscription
      'Who will be using this GitLab subscription?'
    elsif flow == :trial
      'Who will be using this GitLab trial?'
    else
      'Who will be using GitLab?'
    end
  end

  with_them do
    it { is_expected.to have_button(button_text) }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: label_text) }
    it do
      if %i(subscription onboarding).include?(flow)
        is_expected.to have_selector('#progress-bar')
      else
        is_expected.not_to have_selector('#progress-bar')
      end
    end
  end
end
