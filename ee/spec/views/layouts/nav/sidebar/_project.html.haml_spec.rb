# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_project' do
  let_it_be_with_refind(:project) { create(:project, :repository) }

  let(:user) { project.owner }

  before do
    assign(:project, project)
    assign(:repository, project.repository)

    allow(view).to receive(:current_ref).and_return('master')
  end

  describe 'Repository' do
    describe 'Files' do
      it 'has a link to the project file locks path' do
        allow(view).to receive(:current_user).and_return(user)

        render

        expect(rendered).to have_link('Locked Files', href: project_path_locks_path(project))
      end
    end
  end

  describe 'Issues' do
    describe 'Iterations' do
      it 'has a link to the issue iterations path' do
        allow(view).to receive(:current_user).and_return(user)
        stub_licensed_features(iterations: true)

        render

        expect(rendered).to have_link('Iterations', href: project_iterations_path(project))
      end
    end
  end

  describe 'Jira' do
    let_it_be_with_refind(:project) { create(:project, has_external_issue_tracker: true) }

    context 'when Jira service integration is not set' do
      it 'does not have a link to the Jira issues menu' do
        render

        expect(rendered).not_to have_link('Jira Issues', href: project_integrations_jira_issues_path(project))
      end
    end

    context 'when Jira service integration is set' do
      let!(:jira) { create(:jira_integration, project: project, issues_enabled: true, project_key: 'GL') }

      before do
        stub_licensed_features(jira_issues_integration: true)
      end

      it 'has a link to the Jira issue tracker' do
        render

        expect(rendered).to have_link('Jira Issues', href: project_integrations_jira_issues_path(project))
      end

      describe 'Issue List' do
        it 'has a link to Jira issue list' do
          render

          expect(rendered).to have_link('Issue List', href: project_integrations_jira_issues_path(project))
        end
      end

      describe 'Open Jira' do
        it 'has a link to open Jira' do
          render

          expect(rendered).to have_link('Open Jira', href: project.external_issue_tracker.issue_tracker_path)
        end
      end
    end
  end

  describe 'Requirements' do
    let(:user) { project.owner }

    before do
      stub_licensed_features(requirements: true)
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'has a link to the requirements page' do
      render

      expect(rendered).to have_link('Requirements', href: project_requirements_management_requirements_path(project))
    end
  end

  describe 'CI/CD' do
    describe 'Test Cases' do
      let(:license_feature_status) { true }

      before do
        stub_licensed_features(quality_management: license_feature_status)
        allow(view).to receive(:current_user).and_return(user)
      end

      it 'has a link to the test cases page' do
        render

        expect(rendered).to have_link('Test Cases', href: project_quality_test_cases_path(project))
      end

      context 'when license feature :quality_management is not enabled' do
        let(:license_feature_status) { false }

        it 'does not have a link to the test cases page' do
          render

          expect(rendered).not_to have_link('Test Cases', href: project_quality_test_cases_path(project))
        end
      end
    end
  end

  describe 'Security and Compliance' do
    context 'when user does not have permissions' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
      end

      it 'top level navigation link is not visible' do
        render

        expect(rendered).not_to have_link('Security & Compliance', href: project_security_dashboard_index_path(project))
      end
    end

    context 'when user has permissions' do
      before do
        allow(view).to receive(:current_user).and_return(user)
        stub_licensed_features(
          security_dashboard: true,
          security_on_demand_scans: true,
          dependency_scanning: true,
          license_scanning: true,
          threat_monitoring: true,
          security_orchestration_policies: true,
          audit_events: true
        )

        render
      end

      it 'top level navigation link is visible' do
        expect(rendered).to have_link('Security & Compliance', href: project_security_dashboard_index_path(project))
      end

      it 'security dashboard link is visible' do
        expect(rendered).to have_link('Security Dashboard', href: project_security_dashboard_index_path(project))
      end

      it 'security vulnerability report link is visible' do
        expect(rendered).to have_link('Vulnerability Report', href: project_security_vulnerability_report_index_path(project))
      end

      it 'security on demand scans link is visible' do
        expect(rendered).to have_link('On-demand Scans', href: new_project_on_demand_scan_path(project))
      end

      it 'dependency list link is visible' do
        expect(rendered).to have_link('Dependency List', href: project_dependencies_path(project))
      end

      it 'license compliance link is visible' do
        expect(rendered).to have_link('License Compliance', href: project_licenses_path(project))
      end

      it 'threat monitoring link is visible' do
        expect(rendered).to have_link('Threat Monitoring', href: project_threat_monitoring_path(project))
      end

      it 'scan policies link is visible' do
        expect(rendered).to have_link('Scan Policies', href: project_security_policy_path(project))
      end

      it 'security configuration link is visible' do
        expect(rendered).to have_link('Configuration', href: project_security_configuration_path(project))
      end

      it 'audit events link is visible' do
        expect(rendered).to have_link('Audit Events', href: project_audit_events_path(project))
      end
    end
  end

  describe 'Operations' do
    describe 'On-call schedules' do
      before do
        allow(view).to receive(:current_user).and_return(user)
        stub_licensed_features(oncall_schedules: true)
      end

      it 'has a link to the on-call schedules page' do
        render

        expect(rendered).to have_link('On-call Schedules', href: project_incident_management_oncall_schedules_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the on-call schedules page' do
          render

          expect(rendered).not_to have_link('On-call Schedules')
        end
      end
    end

    describe 'Escalation Policies' do
      before do
        allow(view).to receive(:current_user).and_return(user)
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      end

      it 'has a link to the escalation policies page' do
        render

        expect(rendered).to have_link('Escalation Policies', href: project_incident_management_escalation_policies_path(project))
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the escalation policies page' do
          render

          expect(rendered).not_to have_link('Escalation Policies')
        end
      end
    end
  end

  describe 'Analytics' do
    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    describe 'Code Review' do
      it 'has a link to the Code Review analytics page' do
        render

        expect(rendered).to have_link('Code review', href: project_analytics_code_reviews_path(project))
      end

      context 'when user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the Code Review analytics page' do
          render

          expect(rendered).not_to have_link('Code review', href: project_analytics_code_reviews_path(project))
        end
      end
    end

    describe 'Insights' do
      before do
        stub_licensed_features(insights: true)
      end

      it 'has a link to the Insights analytics page' do
        render

        expect(rendered).to have_link('Insights', href: project_insights_path(project))
      end

      context 'when user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the Insights analytics page' do
          render

          expect(rendered).not_to have_link('Insights', href: project_insights_path(project))
        end
      end
    end

    describe 'Issue' do
      before do
        stub_licensed_features(issues_analytics: true)
      end

      it 'has a link to the issue analytics page' do
        render

        expect(rendered).to have_link('Issue', href: project_analytics_issues_analytics_path(project))
      end

      context 'when user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the issue analytics page' do
          render

          expect(rendered).not_to have_link('Issue', href: project_analytics_issues_analytics_path(project))
        end
      end
    end

    describe 'Merge request' do
      before do
        stub_licensed_features(project_merge_request_analytics: true)
      end

      it 'has a link to the merge request analytics page' do
        render

        expect(rendered).to have_link('Merge request', href: project_analytics_merge_request_analytics_path(project))
      end

      context 'when user does not have access' do
        let(:user) { nil }

        it 'does not have a link to the merge request analytics page' do
          render

          expect(rendered).not_to have_link('Merge request', href: project_analytics_merge_request_analytics_path(project))
        end
      end
    end
  end

  describe 'Settings' do
    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    describe 'Monitor' do
      it 'links to settings page' do
        render

        expect(rendered).to have_link('Monitor', href: project_settings_operations_path(project))
      end

      context 'when user is not authorized' do
        let(:user) { nil }

        it 'does not display the link' do
          render

          expect(rendered).not_to have_link('Monitor', href: project_settings_operations_path(project))
        end
      end
    end
  end
end
