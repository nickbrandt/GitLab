# frozen_string_literal: true

require 'spec_helper'

describe 'Group overview', :js, :aggregate_failures do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:empty_project) { create(:project, namespace: group) }

  subject(:visit_page) { visit group_path(group) }

  before do
    stub_feature_flags(first_class_vulnerabilities: false)
    group.add_owner(user)
    sign_in(user)
  end

  context 'when the default value of "Group Overview content" preference is used' do
    it 'displays the Details view' do
      visit_page

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
    end

    let(:user) { create(:user, group_view: :security_dashboard) }

    context 'and Security Dashboard feature is available for a group' do
      let(:group) { create(:group_with_plan, plan: :gold_plan) }
      let(:project) { create(:project, :public, namespace: group) }

      before do
        create(:vulnerability, :with_findings, project: project)
      end

      context 'when the "first_class_vulnerabilities" feature flag is not enabled' do
        it 'displays the Security Dashboard view' do
          visit_page

          expect(page).to have_selector('.js-security-dashboard-table')

          page.within(find('aside')) do
            expect(page).to have_content 'Vulnerabilities over time'
            expect(page).to have_selector('.js-vulnerabilities-chart-time-info')
            expect(page).to have_selector('.js-vulnerabilities-chart-severity-level-breakdown')

            expect(page).to have_content 'Project security status'
            expect(page).to have_selector('.js-projects-security-status')
          end

          page.within(all('div.row')[1]) do
            expect(page).not_to have_content 'Detected'
          end
        end
      end

      context 'when the "first_class_vulnerabilities" feature flag is enabled' do
        before do
          stub_feature_flags(first_class_vulnerabilities: true)
        end

        it 'loads the first class group security dashboard' do
          visit_page

          page.within(all('div.row')[1]) do
            expect(page).to have_content 'Detected'
            expect(page).to have_content 'Severity'
          end
        end
      end
    end

    context 'and Security Dashboard feature is not available for a group' do
      let(:group) { create(:group_with_plan, plan: :bronze_plan) }

      it 'displays the "Security Dashboard unavailable" empty state' do
        visit_page

        page.within(find('.content')) do
          expect(page).to have_content "Either you don't have permission to view this dashboard or "\
                                       'the dashboard has not been setup. Please check your permission settings '\
                                       'with your administrator or check your dashboard configurations to proceed.'
        end
      end
    end
  end
end
