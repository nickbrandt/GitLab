# frozen_string_literal: true

require 'spec_helper'

describe 'User Onboarding' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    allow(Gitlab).to receive(:com?) { true }

    sign_in(user)
  end

  context 'when the feature is enabled', :js do
    before do
      stub_feature_flags(user_onboarding: true)
    end

    describe 'help menu' do
      it 'shows the "Learn GitLab" item in the help menu' do
        visit root_dashboard_path

        find('.header-help-dropdown-toggle').click

        page.within('.header-help') do
          expect(page).to have_link('Learn GitLab', href: explore_onboarding_index_path(from_help_menu: true))
        end
      end
    end

    context 'welcome page' do
      before do
        allow(Project).to receive(:find_by_full_path).and_return(project)
        project.add_guest(user)
      end

      it 'shows the "Learn GitLab" welcome page' do
        visit explore_onboarding_index_path

        expect(page).to have_content('Welcome to the Guided GitLab Tour')
      end
    end
  end

  context 'when the feature is disabled' do
    before do
      stub_feature_flags(user_onboarding: false)
    end

    describe 'help menu' do
      it 'does not show the "Learn GitLab" item in the help menu' do
        visit root_dashboard_path

        find('.header-help-dropdown-toggle').click

        page.within('.header-help') do
          expect(page).not_to have_link('Learn GitLab')
        end
      end
    end
  end
end
