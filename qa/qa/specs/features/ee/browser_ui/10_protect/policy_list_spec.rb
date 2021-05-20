# frozen_string_literal: true

module QA
  RSpec.describe 'Protect' do
    describe 'Threat Monitoring Policy List page' do
      before do
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = Runtime::Env.auto_devops_project_name || 'project-with-protect'
            project.description = 'Project with Protect'
            project.auto_devops_enabled = false
            project.initialize_with_readme = true
          end
        end
      end

      it 'can load Threat Monitoring page and view the policy alert list', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1786' do
        Flow::Login.sign_in

        project.visit!

        Page::Project::Menu.perform(&:click_on_threat_monitoring)

        EE::Page::Project::ThreatMonitoring::AlertsList.perform do |alerts_list|
          expect(alerts_list).to have_alerts_tab
          expect(alerts_list).to have_alerts_list
        end
      end
    end
  end
end
