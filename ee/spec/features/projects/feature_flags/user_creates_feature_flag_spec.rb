# frozen_string_literal: true

require 'spec_helper'

describe 'User creates feature flag', :js do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_developer(user)
    stub_licensed_features(feature_flags: true)
    stub_feature_flags(feature_flag_permissions: false)
    sign_in(user)
  end

  it 'user creates a flag enabled for user ids' do
    visit(new_project_feature_flag_path(project))
    set_feature_flag_info('test_feature', 'Test feature')
    within_strategy_row(1) do
      select 'User IDs', from: 'Type'
      fill_in 'User IDs', with: 'user1, user2'
      environment_plus_button.click
      environment_search_input.set('production')
      environment_search_results.first.click
    end
    click_button 'Create feature flag'

    expect_user_to_see_feature_flags_index_page
    expect(page).to have_text('test_feature')
  end

  context 'with new version flags disabled' do
    before do
      stub_feature_flags(feature_flags_new_version: false)
    end

    context 'when creates without changing scopes' do
      before do
        visit(new_project_feature_flag_path(project))
        set_feature_flag_info('ci_live_trace', 'For live trace')
        click_button 'Create feature flag'
        expect(page).to have_current_path(project_feature_flags_path(project))
      end

      it 'shows the created feature flag' do
        within_feature_flag_row(1) do
          expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
          expect(page).to have_css('.js-feature-flag-status button.is-checked')

          within_feature_flag_scopes do
            expect(page.find('.badge:nth-child(1)')).to have_content('*')
            expect(page.find('.badge:nth-child(1)')['class']).to include('badge-active')
          end
        end
      end

      it 'records audit event' do
        visit(project_audit_events_path(project))

        expect(page).to have_text("Created feature flag ci_live_trace with description \"For live trace\".")
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
          expect(page).to have_css('.js-feature-flag-status button.is-checked')

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
          within_environment_spec do
            find('.js-env-input').set("review/*")
            find('.js-create-button').click
          end
        end

        within_scope_row(2) do
          within_status { find('.project-feature-toggle').click }
        end

        click_button 'Create feature flag'
      end

      it 'shows the created feature flag' do
        within_feature_flag_row(1) do
          expect(page.find('.feature-flag-name')).to have_content('mr_train')
          expect(page).to have_css('.js-feature-flag-status button.is-checked')

          within_feature_flag_scopes do
            expect(page.find('.badge:nth-child(1)')).to have_content('*')
            expect(page.find('.badge:nth-child(1)')['class']).to include('badge-active')
            expect(page.find('.badge:nth-child(2)')).to have_content('review/*')
            expect(page.find('.badge:nth-child(2)')['class']).to include('badge-active')
          end
        end
      end
    end

    context 'when searches an environment name for scope creation' do
      let!(:environment) { create(:environment, name: 'production', project: project) }

      before do
        visit(new_project_feature_flag_path(project))
        set_feature_flag_info('mr_train', '')

        within_scope_row(2) do
          within_environment_spec do
            find('.js-env-input').set('prod')
            click_button 'production'
          end
        end

        click_button 'Create feature flag'
      end

      it 'shows the created feature flag' do
        within_feature_flag_row(1) do
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
    end
  end

  private

  def set_feature_flag_info(name, description)
    fill_in 'Name', with: name
    fill_in 'Description', with: description
  end

  def environment_plus_button
    find('.js-new-environments-dropdown')
  end

  def environment_search_input
    find('.js-new-environments-dropdown input')
  end

  def environment_search_results
    all('.js-new-environments-dropdown button.dropdown-item')
  end
end
