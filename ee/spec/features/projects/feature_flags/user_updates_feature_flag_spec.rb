# frozen_string_literal: true

require 'spec_helper'

describe 'User updates feature flag', :js do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  let!(:feature_flag) do
    create_flag(project, 'ci_live_trace', true,
                description: 'For live trace feature')
  end

  let!(:scope) { create_scope(feature_flag, 'review/*', true) }

  before do
    project.add_developer(user)
    stub_licensed_features(feature_flags: true)
    stub_feature_flags(feature_flag_permissions: false)
    sign_in(user)

    visit(edit_project_feature_flag_path(project, feature_flag))
  end

  it 'user sees persisted default scope' do
    within_scope_row(1) do
      within_environment_spec do
        expect(page).to have_content('* (All Environments)')
      end

      within_status do
        expect(find('.project-feature-toggle')['aria-label'])
          .to eq('Toggle Status: ON')
      end
    end
  end

  context 'when user updates a status of a scope' do
    before do
      within_scope_row(2) do
        within_status { find('.project-feature-toggle').click }
      end

      click_button 'Save changes'
      expect(page).to have_current_path(project_feature_flags_path(project))
    end

    it 'shows the updated feature flag' do
      within_feature_flag_row(1) do
        expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
        expect(page).to have_css('.js-feature-flag-status button.is-checked')

        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(1)')).to have_content('*')
          expect(page.find('.badge:nth-child(1)')['class']).to include('badge-active')
          expect(page.find('.badge:nth-child(2)')).to have_content('review/*')
          expect(page.find('.badge:nth-child(2)')['class']).to include('badge-inactive')
        end
      end
    end

    it 'records audit event' do
      visit(project_audit_events_path(project))

      expect(page).to(
        have_text("Updated feature flag ci_live_trace. Updated rule review/* active state from true to false.")
      )
    end
  end

  context 'when user adds a new scope' do
    before do
      within_scope_row(3) do
        within_environment_spec do
          find('.js-env-input').set('production')
          find('.js-create-button').click
        end
      end

      click_button 'Save changes'
      expect(page).to have_current_path(project_feature_flags_path(project))
    end

    it 'shows the newly created scope' do
      within_feature_flag_row(1) do
        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(3)')).to have_content('production')
          expect(page.find('.badge:nth-child(3)')['class']).to include('badge-inactive')
        end
      end
    end

    it 'records audit event' do
      visit(project_audit_events_path(project))

      expect(page).to(
        have_text("Updated feature flag ci_live_trace")
      )
    end
  end

  context 'when user deletes a scope' do
    before do
      within_scope_row(2) do
        within_delete { find('.js-delete-scope').click }
      end

      click_button 'Save changes'
      expect(page).to have_current_path(project_feature_flags_path(project))
    end

    it 'shows the updated feature flag' do
      within_feature_flag_row(1) do
        within_feature_flag_scopes do
          expect(page).to have_css('.badge:nth-child(1)')
          expect(page).not_to have_css('.badge:nth-child(2)')
        end
      end
    end

    it 'records audit event' do
      visit(project_audit_events_path(project))

      expect(page).to(
        have_text("Updated feature flag ci_live_trace")
      )
    end
  end
end
