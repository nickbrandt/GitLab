# frozen_string_literal: true

require 'spec_helper'

describe 'User sees feature flag list', :js do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_developer(user)
    stub_licensed_features(feature_flags: true)
    sign_in(user)
  end

  context 'when there are feature flags and scopes' do
    before do
      create_flag(project, 'ci_live_trace', false).tap do |feature_flag|
        create_scope(feature_flag, 'review/*', true)
      end
      create_flag(project, 'drop_legacy_artifacts', false)
      create_flag(project, 'mr_train', true).tap do |feature_flag|
        create_scope(feature_flag, 'production', false)
      end

      visit(project_feature_flags_path(project))
    end

    it 'user sees the first flag' do
      within_feature_flag_row(1) do
        expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
        expect(page).to have_css('.js-feature-flag-status button:not(.is-checked)')

        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(1)')).to have_content('*')
          expect(page.find('.badge:nth-child(1)')['class']).to include('badge-inactive')
          expect(page.find('.badge:nth-child(2)')).to have_content('review/*')
          expect(page.find('.badge:nth-child(2)')['class']).to include('badge-active')
        end
      end
    end

    it 'user sees the second flag' do
      within_feature_flag_row(2) do
        expect(page.find('.feature-flag-name')).to have_content('drop_legacy_artifacts')
        expect(page).to have_css('.js-feature-flag-status button:not(.is-checked)')

        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(1)')).to have_content('*')
          expect(page.find('.badge:nth-child(1)')['class']).to include('badge-inactive')
        end
      end
    end

    it 'user sees the third flag' do
      within_feature_flag_row(3) do
        expect(page.find('.feature-flag-name')).to have_content('mr_train')
        expect(page).to have_css('.js-feature-flag-status button.is-checked')

        within_feature_flag_scopes do
          expect(page.find('.badge:nth-child(1)')).to have_content('*')
          expect(page.find('.badge:nth-child(1)')['class']).to include('badge-active')
          expect(page.find('.badge:nth-child(2)')).to have_content('production')
          expect(page.find('.badge:nth-child(2)')['class']).to include('badge-inactive')
        end
      end
    end

    it 'user updates the status toggle' do
      within_feature_flag_row(1) do
        page.find('.js-feature-flag-status button').click

        expect(page).to have_css('.js-feature-flag-status button.is-checked')
      end

      visit(project_audit_events_path(project))

      expect(page).to(
        have_text('Updated feature flag ci_live_trace. Updated active from "false" to "true".')
      )
    end
  end

  context 'when there are no feature flags' do
    before do
      visit(project_feature_flags_path(project))
    end

    it 'shows empty page' do
      expect(page).to have_text 'Get started with feature flags'
      expect(page).to have_selector('.btn-success', text: 'New feature flag')
      expect(page).to have_selector('.btn-primary.btn-inverted', text: 'Configure')
    end
  end
end
