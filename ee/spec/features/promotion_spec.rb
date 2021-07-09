# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Promotions', :js do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:otherdeveloper) { create(:user, name: 'TheOtherDeveloper') }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:milestone) { create(:milestone, project: project, start_date: Date.today, due_date: 7.days.from_now) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let(:otherproject) { create(:project, :repository, namespace: otherdeveloper.namespace) }

  describe 'for merge request improve', :js do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      project.add_maintainer(user)
      sign_in(user)
    end

    it 'appears in project edit page' do
      visit edit_project_path(project)

      expect(find('#promote_mr_features')).to have_content 'Improve merge requests'
    end

    it 'does not show when cookie is set' do
      visit edit_project_path(project)

      within('#promote_mr_features') do
        find('.close').click
      end

      wait_for_requests

      visit edit_project_path(project)

      expect(page).not_to have_selector('#promote_mr_features')
    end
  end

  describe 'for repository features', :js do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      project.add_maintainer(user)
      sign_in(user)
    end

    it 'appears in repository settings page' do
      visit project_settings_repository_path(project)

      expect(find('#promote_repository_features')).to have_content 'Improve repositories with GitLab Enterprise Edition'
    end

    it 'does not show when cookie is set' do
      visit project_settings_repository_path(project)

      within('#promote_repository_features') do
        find('.close').click
      end

      visit project_settings_repository_path(project)

      expect(page).not_to have_selector('#promote_repository_features')
    end
  end

  describe 'for burndown charts', :js do
    before do
      stub_application_setting(check_namespace_plan: true)
      allow(Gitlab).to receive(:com?) { true }

      project.add_maintainer(user)
      sign_in(user)
    end

    it 'appears in milestone page' do
      visit project_milestone_path(project, milestone)

      expect(find('#promote_burndown_charts')).to have_content 'Upgrade your plan to improve milestones with Burndown Charts.'
    end

    it 'does not show when cookie is set' do
      visit project_milestone_path(project, milestone)

      within('#promote_burndown_charts') do
        find('.close').click
      end

      visit project_milestone_path(project, milestone)

      expect(page).not_to have_selector('#promote_burndown_charts')
    end
  end

  describe 'for epics in issues sidebar', :js do
    shared_examples 'Epics promotion' do
      it 'appears on the page' do
        visit project_issue_path(project, issue)
        wait_for_requests

        click_epic_link

        expect(find('.promotion-issue-sidebar-message')).to have_content 'Epics let you manage your portfolio of projects more efficiently'
      end

      it 'is removed after dismissal' do
        visit project_issue_path(project, issue)
        wait_for_requests

        click_epic_link
        find('.js-epics-sidebar-callout .js-close-callout').click

        expect(page).not_to have_selector('.promotion-issue-sidebar-message')
      end

      it 'does not appear on page after dismissal and reload' do
        visit project_issue_path(project, issue)
        wait_for_requests

        click_epic_link
        find('.js-epics-sidebar-callout .js-close-callout').click
        visit project_issue_path(project, issue)

        expect(page).not_to have_selector('.js-epics-sidebar-callout')
      end

      it 'closes dialog when clicking on X, but not dismiss it' do
        visit project_issue_path(project, issue)
        wait_for_requests

        click_epic_link
        find('.js-epics-sidebar-callout .dropdown-menu-close').click

        expect(page).to have_selector('.js-epics-sidebar-callout')
        expect(page).to have_selector('.promotion-issue-sidebar-message', visible: false)
      end
    end

    context 'gitlab.com' do
      before do
        stub_application_setting(check_namespace_plan: true)
        allow(Gitlab).to receive(:com?) { true }

        project.add_maintainer(user)
        sign_in(user)
      end

      it_behaves_like 'Epics promotion'
    end

    context 'self hosted' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(check_namespace_plan: false)

        project.add_maintainer(user)
        sign_in(user)
      end

      it_behaves_like 'Epics promotion'
    end
  end

  describe 'for issue weight', :js do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      project.add_maintainer(user)
      sign_in(user)
    end

    it 'appears on the page', :js do
      visit project_issue_path(project, issue)
      wait_for_requests

      click_link 'Learn more'

      expect(find('.promotion-issue-weight-sidebar-message')).to have_content 'Improve issues management with Issue weight and GitLab Enterprise Edition'
    end

    it 'is removed after dismissal' do
      visit project_issue_path(project, issue)
      wait_for_requests

      click_link 'Learn more'
      click_link 'Not now, thanks'

      expect(page).not_to have_content('.js-weight-sidebar-callout')
    end

    it 'does not appear on page after dismissal and reload' do
      visit project_issue_path(project, issue)
      wait_for_requests

      click_link 'Learn more'
      click_link 'Not now, thanks'
      visit project_issue_path(project, issue)

      expect(page).not_to have_selector('.js-weight-sidebar-callout')
    end

    it 'closes dialog when clicking on X, but not dismiss it' do
      visit project_issue_path(project, issue)
      wait_for_requests

      click_link 'Learn more'
      click_link 'Learn more'

      expect(page).to have_selector('.js-weight-sidebar-callout')
      expect(page).to have_selector('.promotion-issue-sidebar-message', visible: false)
    end

    context 'when checking namespace plans' do
      before do
        stub_application_setting(check_namespace_plan: true)

        group.add_owner(user)
      end

      it 'appears on the page', :js do
        visit project_issue_path(project, issue)
        wait_for_requests

        click_link 'Learn more'

        expect(page).to have_link 'Try it for free', href: new_trial_registration_path(glm_source: 'gitlab.com', glm_content: 'issue_weights'), class: 'promotion-trial-cta'
        expect(find('.js-close-callout.js-close-session.tr-issue-weights-not-now-cta')).to have_content 'Not now, thanks!'
      end
    end
  end

  describe 'for issue templates', :js do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      project.add_maintainer(user)
      sign_in(user)
    end

    it 'appears on the page', :js do
      visit new_project_issue_path(project)
      wait_for_requests

      find('#promotion-issue-template-link').click

      expect(find('.promotion-issue-template-message')).to have_content 'Description templates allow you to define context-specific templates for issue and merge request description fields for your project.'
    end
  end

  describe 'for project audit events', :js do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      project.add_maintainer(user)
      sign_in(user)
    end

    include_context '"Security & Compliance" permissions' do
      let(:response) { inspect_requests { visit project_audit_events_path(project) }.first }
    end

    it 'appears on the page' do
      visit project_audit_events_path(project)

      expect(find('.user-callout-copy')).to have_content 'Track your project with Audit Events'
    end
  end

  describe 'for group contribution analytics', :js do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      group.add_owner(user)
      sign_in(user)
    end

    it 'appears on the page' do
      visit group_contribution_analytics_path(group)

      expect(find('.user-callout-copy')).to have_content 'Track activity with Contribution Analytics.'
    end
  end

  describe 'for group webhooks' do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      group.add_owner(user)
      sign_in(user)
    end

    it 'appears on the page' do
      visit group_hooks_path(group)

      expect(find('.user-callout-copy')).to have_content 'Add Group Webhooks'
    end
  end

  describe 'for advanced search', :js do
    before do
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)

      sign_in(user)
    end

    it 'appears on seearch page' do
      visit search_path

      submit_search('chosen')

      expect(find('#promote_advanced_search')).to have_content 'Improve search with Advanced Search and GitLab Enterprise Edition.'
    end

    it 'does not show when cookie is set' do
      visit search_path
      submit_search('chosen')

      within('#promote_advanced_search') do
        find('.close').click
      end

      visit search_path
      submit_search('chosen')

      expect(page).not_to have_selector('#promote_advanced_search')
    end
  end

  def click_epic_link
    find('.js-epics-sidebar-callout .btn-link').click
  end
end
