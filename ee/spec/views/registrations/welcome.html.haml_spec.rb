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

  where(:in_subscription_flow, :in_trial_flow, :in_invitation_flow, :in_oauth_flow, :onboarding_issues_experiment_enabled, :shows_progress_bar, :label_key, :is_continue_btn) do
    false | false | false | false | false | false | nil           | false # regular
    true  | false | false | false | false | true  | :subscription | true  # subscription
    false | true  | false | false | false | false | :trial        | true  # trial
    false | false | true  | false | false | false | nil           | false # invitation
    false | false | false | true  | false | false | nil           | false # oauth
    false | false | false | false | true  | true  | nil           | true  # onboarding
    true  | false | false | false | true  | true  | :subscription | true  # onboarding + subscription
    false | true  | false | false | true  | false | :trial        | true  # onboarding + trial
    false | false | true  | false | true  | false | nil           | false # onboarding + invitation
    false | false | false | true  | true  | false | nil           | false # onboarding + oauth
  end

  def button_text
    is_continue_btn ? 'Continue' : 'Get started!'
  end

  def label_text
    if label_key == :subscription
      'Who will be using this GitLab subscription?'
    elsif label_key == :trial
      'Who will be using this GitLab trial?'
    else
      'Who will be using GitLab?'
    end
  end

  with_them do
    it { is_expected.to have_button(button_text) }
    it { is_expected.to have_selector('label[for="user_setup_for_company"]', text: label_text) }
    it do
      if shows_progress_bar
        is_expected.to have_selector('#progress-bar')
      else
        is_expected.not_to have_selector('#progress-bar')
      end
    end
  end
end
