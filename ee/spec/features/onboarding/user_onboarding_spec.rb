# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Onboarding' do
  include MobileHelpers

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
      before do
        visit root_dashboard_path

        find('.header-help-dropdown-toggle').click
      end

      it 'shows the "Learn GitLab" item in the help menu' do
        page.within('.header-help') do
          expect(page).to have_link('Learn GitLab', href: explore_onboarding_index_path(from_help_menu: true))
        end
      end

      context 'when on a mobile device' do
        before do
          resize_screen_sm
        end

        it 'does not show the "Learn GitLab" item in the help menu' do
          page.within('.header-user') do
            expect(page).not_to have_link('Learn GitLab')
          end
        end
      end
    end

    describe 'welcome page' do
      before do
        allow(Project).to receive(:find_by_full_path).and_return(project)
        project.add_guest(user)
      end

      it 'shows the "Learn GitLab" welcome page' do
        visit explore_onboarding_index_path

        expect(page).to have_content('Welcome to the Guided GitLab Tour')
      end

      context 'when on a mobile device' do
        before do
          resize_screen_sm
        end

        it 'does not show the "Learn GitLab" welcome page' do
          visit explore_onboarding_index_path
          expect(page).not_to have_content('Welcome to the Guided GitLab Tour')
        end
      end
    end

    describe 'onboarding helper' do
      before do
        allow(Project).to receive(:find_by_full_path).and_return(project)
        project.add_guest(user)
      end

      it 'shows the onboarding helper on the onboarding project' do
        visit explore_onboarding_index_path

        find('.btn-success').click

        expect(page).to have_css('#js-onboarding-helper', visible: true)
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

    describe 'welcome page' do
      it 'does not show the "Learn GitLab" welcome page' do
        visit explore_onboarding_index_path

        expect(page).not_to have_content('Welcome to the Guided GitLab Tour')
      end
    end

    describe 'onboarding helper' do
      it 'does not show the onboarding helper on the onboarding project' do
        visit project_path(project)

        expect(page).not_to have_css('#js-onboarding-helper')
      end
    end
  end
end
