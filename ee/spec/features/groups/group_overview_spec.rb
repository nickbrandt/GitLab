# frozen_string_literal: true

require 'spec_helper'

describe 'Group overview', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:empty_project) { create(:project, namespace: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'when the default value of "Group Overview content" preference is used' do
    it 'displays the Details view' do
      visit group_path(group)

      page.within(find('.content')) do
        expect(page).to have_content 'Subgroups and projects'
        expect(page).to have_content 'Shared projects'
        expect(page).to have_content 'Archived projects'
      end
    end
  end

  context 'when Security Dashboard view is set as default' do
    before do
      stub_licensed_features(security_dashboard: true)
      enable_namespace_license_check!

      create(:gitlab_subscription, hosted_plan: group.plan, namespace: group)
    end

    let(:user) { create(:user, group_view: :security_dashboard) }

    context 'and Security Dashboard feature is available for a group' do
      let(:group) { create(:group, plan: :gold_plan) }

      it 'displays the Security Dashboard view' do
        visit group_path(group)

        expect(page).to have_selector('.js-security-dashboard-table')

        page.within(find('aside')) do
          expect(page).to have_content 'Vulnerabilities over time'
          expect(page).to have_selector('.js-vulnerabilities-chart-time-info')
          expect(page).to have_selector('.js-vulnerabilities-chart-severity-level-breakdown')

          expect(page).to have_content 'Project security status'
          expect(page).to have_selector('.js-projects-security-status')
        end
      end
    end

    context 'and Security Dashboard feature is not available for a group' do
      let(:group) { create(:group, plan: :bronze_plan) }

      it 'displays the "Security Dashboard unavailable" empty state' do
        visit group_path(group)

        page.within(find('.content')) do
          expect(page).to have_content "Either you don't have permission to view this dashboard or "\
                                       'the dashboard has not been setup. Please check your permission settings '\
                                       'with your administrator or check your dashboard configurations to proceed.'
        end
      end
    end
  end
end
