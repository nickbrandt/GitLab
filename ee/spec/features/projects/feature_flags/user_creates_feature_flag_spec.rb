# frozen_string_literal: true

require 'spec_helper'

describe 'User creates feature flag', :js do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_developer(user)
    stub_licensed_features(feature_flags: true)
    sign_in(user)
  end

  context 'when creates without changing scopes' do
    before do
      visit(new_project_feature_flag_path(project))
      set_feature_flag_info('ci_live_trace', 'For live trace')
      click_button 'Create feature flag'
    end

    it 'shows the created feature flag' do
      within_feature_flag_row(1) do
        expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
        expect(page).to have_css('.js-feature-flag-status .badge-success')

        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(1)')).to have_content('*')
          expect(page.find('.badge:nth-child(1)')['class']).to include('badge-active')
        end
      end
    end
  end

  context 'when creates with disabling the default scope' do
    before do
      visit(new_project_feature_flag_path(project))
      set_feature_flag_info('ci_live_trace', 'For live trace')

      within_scope_row(1) do
        within_status { find('.project-feature-toggle').click }
      end

      click_button 'Create feature flag'
    end

    it 'shows the created feature flag' do
      within_feature_flag_row(1) do
        expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
        expect(page).to have_css('.js-feature-flag-status .badge-danger')

        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(1)')).to have_content('*')
          expect(page.find('.badge:nth-child(1)')['class']).to include('badge-inactive')
        end
      end
    end
  end

  context 'when creates with an additional scope' do
    before do
      visit(new_project_feature_flag_path(project))
      set_feature_flag_info('mr_train', '')

      within_scope_row(2) do
        within_environment_spec { find('.js-new-scope-name').set("review/*") }
      end

      within_scope_row(2) do
        within_status { find('.project-feature-toggle').click }
      end

      click_button 'Create feature flag'
    end

    it 'shows the created feature flag' do
      within_feature_flag_row(1) do
        expect(page.find('.feature-flag-name')).to have_content('mr_train')
        expect(page).to have_css('.js-feature-flag-status .badge-success')

        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(1)')).to have_content('*')
          expect(page.find('.badge:nth-child(1)')['class']).to include('badge-active')
          expect(page.find('.badge:nth-child(2)')).to have_content('review/*')
          expect(page.find('.badge:nth-child(2)')['class']).to include('badge-active')
        end
      end
    end
  end

  private

  def set_feature_flag_info(name, description)
    fill_in 'Name', with: name
    fill_in 'Description', with: description
  end
end
