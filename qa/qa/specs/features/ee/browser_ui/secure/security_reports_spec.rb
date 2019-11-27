# frozen_string_literal: true

require 'pathname'

module QA
  # https://gitlab.com/gitlab-org/gitlab/issues/34900
  context 'Secure', :docker, :quarantine do
    let(:number_of_dependencies_in_fixture) { 1309 }
    let(:total_vuln_count) { 54 }
    let(:dependency_scan_vuln_count) { 4 }
    let(:dependency_scan_example_vuln) { 'jQuery before 3.4.0' }
    let(:container_scan_vuln_count) { 8 }
    let(:container_scan_example_vuln) { 'CVE-2017-18269 in glibc' }
    let(:sast_scan_vuln_count) { 33 }
    let(:sast_scan_example_vuln) { 'Cipher with no integrity' }
    let(:dast_scan_vuln_count) { 9 }
    let(:dast_scan_example_vuln) { 'Cookie Without SameSite Attribute' }

    describe 'Security Reports' do
      after do
        Service::DockerRun::GitlabRunner.new(@executor).remove!

        Runtime::Feature.enable('job_log_json') if @job_log_json_flag_enabled
      end

      before do
        @executor = "qa-runner-#{Time.now.to_i}"

        # Handle WIP Job Logs flag - https://gitlab.com/gitlab-org/gitlab/issues/31162
        @job_log_json_flag_enabled = Runtime::Feature.enabled?('job_log_json')
        Runtime::Feature.disable('job_log_json') if @job_log_json_flag_enabled

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

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

        wait_for_job "dast"
      end

      it 'displays security reports in the pipeline' do
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_on_security

          expect(pipeline).to have_vulnerability_count_of total_vuln_count

          filter_report_and_perform(pipeline, "Dependency Scanning") do
            expect(pipeline).to have_vulnerability_count_of dependency_scan_vuln_count
            expect(pipeline).to have_content dependency_scan_example_vuln
          end

          filter_report_and_perform(pipeline, "Container Scanning") do
            expect(pipeline).to have_vulnerability_count_of container_scan_vuln_count
            expect(pipeline).to have_content container_scan_example_vuln
          end

          filter_report_and_perform(pipeline, "SAST") do
            expect(pipeline).to have_vulnerability_count_of sast_scan_vuln_count
            expect(pipeline).to have_content sast_scan_example_vuln
          end

          filter_report_and_perform(pipeline, "DAST") do
            expect(pipeline).to have_vulnerability_count_of dast_scan_vuln_count
            expect(pipeline).to have_content dast_scan_example_vuln
          end
        end
      end

      it 'displays security reports in the project security dashboard' do
        Page::Project::Menu.perform(&:click_project)
        Page::Project::Menu.perform(&:click_on_security_dashboard)

        EE::Page::Project::Secure::Show.perform do |dashboard|
          filter_report_and_perform(dashboard, "Dependency Scanning") do
            expect(dashboard).to have_low_vulnerability_count_of 1
          end

          filter_report_and_perform(dashboard, "Container Scanning") do
            expect(dashboard).to have_low_vulnerability_count_of 2
          end

          filter_report_and_perform(dashboard, "SAST") do
            expect(dashboard).to have_low_vulnerability_count_of 17
          end

          filter_report_and_perform(dashboard, "DAST") do
            expect(dashboard).to have_low_vulnerability_count_of 8
          end
        end
      end

      it 'displays security reports in the group security dashboard' do
        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform do |groups|
          groups.click_group @project.group.path
        end
        Page::Group::Menu.perform(&:click_group_security_link)

        EE::Page::Group::Secure::Show.perform do |dashboard|
          dashboard.filter_project(@project.name)

          filter_report_and_perform(dashboard, "Dependency Scanning") do
            expect(dashboard).to have_content dependency_scan_example_vuln
          end

          filter_report_and_perform(dashboard, "Container Scanning") do
            expect(dashboard).to have_content container_scan_example_vuln
          end

          filter_report_and_perform(dashboard, "SAST") do
            expect(dashboard).to have_content sast_scan_example_vuln
          end

          filter_report_and_perform(dashboard, "DAST") do
            expect(dashboard).to have_content dast_scan_example_vuln
          end
        end
      end

      it 'displays the Dependency List' do
        Page::Project::Menu.perform(&:click_on_dependency_list)

        EE::Page::Project::Secure::DependencyList.perform do |dependency_list|
          expect(dependency_list).to have_dependency_count_of number_of_dependencies_in_fixture
        end
      end
    end

    def wait_for_job(job_name)
      Page::Project::Pipeline::Show.perform do |pipeline|
        pipeline.click_job(job_name)
      end
      Page::Project::Job::Show.perform do |job|
        expect(job).to be_successful(timeout: 600)
      end
    end

    def filter_report_and_perform(page, report)
      page.filter_report_type report
      yield
      page.filter_report_type report # Disable filter to avoid combining
    end
  end
end
