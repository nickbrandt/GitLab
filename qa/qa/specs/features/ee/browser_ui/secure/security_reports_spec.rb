# frozen_string_literal: true

require 'pathname'

module QA
  context 'Secure', :docker do
    let(:number_of_dependencies_in_fixture) { 1309 }
    let(:dependency_scan_example_vuln) { 'jQuery before 3.4.0' }

    def login
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.perform(&:sign_in_using_credentials)
    end

    def wait_for_job(job_name)
      Page::Project::Pipeline::Show.perform do |pipeline|
        pipeline.click_job(job_name)
      end
      Page::Project::Job::Show.perform do |job|
        expect(job).to be_successful(timeout: 600)
      end
    end

    describe 'Security Reports' do
      after do
        Service::Runner.new(@executor).remove!
      end

      before do
        @executor = "qa-runner-#{Time.now.to_i}"

        login

        @project = Resource::Project.fabricate_via_api! do |p|
          p.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          p.description = 'Project with Secure'
        end

        Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = @executor
          runner.tags = %w[qa test]
        end

        # Push fixture to generate Secure reports
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../../ee/fixtures/secure_premade_reports')
          push.commit_message = 'Create Secure compatible application to serve premade reports'
        end.project.visit!

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)
      end

      it 'displays the Dependency Scanning report in the pipeline' do
        wait_for_job "dependency_scanning"

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_on_security
          pipeline.filter_report_type "Dependency Scanning"
          expect(pipeline).to have_vulnerability_count_of 4
          expect(pipeline).to have_content(dependency_scan_example_vuln)
        end
      end

      it 'displays the Dependency Scanning report in the project security dashboard' do
        wait_for_job "dependency_scanning"

        Page::Project::Menu.perform(&:click_project)
        Page::Project::Menu.perform(&:click_on_security_dashboard)

        EE::Page::Project::Secure::Show.perform do |dashboard|
          dashboard.filter_report_type "Dependency Scanning"
          expect(dashboard).to have_low_vulnerability_count_of "1"
        end
      end

      it 'displays the Dependency Scanning report in the group security dashboard' do
        wait_for_job "dependency_scanning"

        Page::Main::Menu.perform { |page| page.go_to_groups }
        Page::Dashboard::Groups.perform { |page| page.click_group(@project.group.path) }
        EE::Page::Group::Menu.perform { |page| page.click_group_security_link }

        EE::Page::Group::Secure::Show.perform do |dashboard|
          dashboard.filter_project(@project.name)
          dashboard.filter_report_type "Dependency Scanning"
          expect(dashboard).to have_content dependency_scan_example_vuln
        end
      end

      it 'displays the Dependency List' do
        wait_for_job "dependency_scanning"

        Page::Project::Menu.perform(&:click_on_dependency_list)

        EE::Page::Project::Secure::DependencyList.perform do |page|
          expect(page).to have_dependency_count_of number_of_dependencies_in_fixture
        end
      end
    end
  end
end
