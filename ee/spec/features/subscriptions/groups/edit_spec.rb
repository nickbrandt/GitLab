# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:params) { {} }
  let(:part_of_onboarding_issues_experiment) { false }

  describe 'on GitLab.com' do
    before do
      group.add_owner(user)
      gitlab_sign_in(user)
      stub_experiment_for_user(onboarding_issues: part_of_onboarding_issues_experiment)
      stub_request(:get, 'https://customers.gitlab.com/gitlab_plans?plan=free')
        .to_return(status: 200, body: '{}', headers: {})

      visit edit_subscriptions_group_path(group.path, params)
    end

    it 'shows the group edit page without a progress bar' do
      expect(page).to have_content('Create your group')
      expect(page).not_to have_content('1. Your profile')
    end

    context 'when showing for a new user' do
      let(:params) { { new_user: true } }

      it 'shows the progress bar with the correct steps' do
        expect(page).to have_content('1. Your profile 2. Checkout 3. Your GitLab group')
      end

      context 'when part of the onboarding issues experiment' do
        let(:part_of_onboarding_issues_experiment) { true }

        it 'shows the progress bar with the correct steps' do
          expect(page).to have_content('1. Your profile 2. Checkout 3. Your GitLab group 4. Your first project')
        end
      end
    end
  end
end
