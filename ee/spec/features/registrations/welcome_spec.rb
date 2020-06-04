# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen', :js do
  let_it_be(:user) { create(:user) }

  let(:in_invitation_flow) { false }
  let(:in_subscription_flow) { false }
  let(:part_of_onboarding_issues_experiment) { false }

  describe 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      gitlab_sign_in(user)
      allow_any_instance_of(EE::RegistrationsHelper).to receive(:in_invitation_flow?).and_return(in_invitation_flow)
      allow_any_instance_of(EE::RegistrationsHelper).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
      stub_experiment_for_user(onboarding_issues: part_of_onboarding_issues_experiment)

      visit users_sign_up_welcome_path
    end

    it 'shows the welcome page without a progress bar' do
      expect(page).to have_content('Welcome to GitLab.com')
      expect(page).not_to have_content('1. Your profile')
    end

    context 'when in the subscription flow' do
      let(:in_subscription_flow) { true }

      it 'shows the progress bar with the correct steps' do
        expect(page).to have_content('1. Your profile 2. Checkout 3. Your GitLab group')
      end
    end

    context 'when part of the onboarding issues experiment' do
      let(:part_of_onboarding_issues_experiment) { true }

      it 'shows the progress bar with the correct steps' do
        expect(page).to have_content('1. Your profile 2. Your GitLab group 3. Your first project')
      end

      context 'when in the invitation flow' do
        let(:in_invitation_flow) { true }

        it 'does not show the progress bar' do
          expect(page).not_to have_content('1. Your profile')
        end
      end
    end

    context 'when in the subscription flow and part of the onboarding issues experiment' do
      let(:in_subscription_flow) { true }
      let(:part_of_onboarding_issues_experiment) { true }

      it 'shows the progress bar with the correct steps' do
        expect(page).to have_content('1. Your profile 2. Checkout 3. Your GitLab group 4. Your first project')
      end
    end
  end
end
