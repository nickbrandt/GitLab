# frozen_string_literal: true

require 'pathname'

module QA
  context 'Secure', :docker do
    let(:approved_license_name) { "MIT" }
    let(:denied_license_name) { "WTFPL" }

    describe 'License Compliance settings page' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          project.description = 'Project with Secure'
        end

        @project.visit!
        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CICD.perform(&:expand_license_compliance)
      end

      it 'can approve a license in the settings page' do
        QA::EE::Page::Project::Settings::LicenseCompliance.perform do |license_compliance|
          license_compliance.approve_license approved_license_name

          expect(license_compliance).to have_approved_license approved_license_name
        end
      end

      it 'can deny a license in the settings page' do
        QA::EE::Page::Project::Settings::LicenseCompliance.perform do |license_compliance|
          license_compliance.deny_license denied_license_name

          expect(license_compliance).to have_denied_license denied_license_name
        end
      end
    end

    describe 'License Compliance pipeline reports' do
      let(:number_of_licenses_in_fixture) { 2 }

      after do
        Service::DockerRun::GitlabRunner.new(@executor).remove!
      end

      before do
        @executor = "qa-runner-#{Time.now.to_i}"

        # Handle WIP Job Logs flag - https://gitlab.com/gitlab-org/gitlab/issues/31162
        @job_log_json_flag_enabled = Runtime::Feature.enabled?('job_log_json')
        Runtime::Feature.disable('job_log_json') if @job_log_json_flag_enabled

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          project.description = 'Project with Secure'
        end

        Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = @executor
          runner.tags = %w[qa test]
        end

        # Push fixture to generate Secure reports
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = @project
          project_push.directory = Pathname
            .new(__dir__)
            .join('../../../../../ee/fixtures/secure_premade_reports')
          project_push.commit_message = 'Create Secure compatible application to serve premade reports'
        end.project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CICD.perform(&:expand_license_compliance)
        QA::EE::Page::Project::Settings::LicenseCompliance.perform do |license_compliance|
          license_compliance.approve_license approved_license_name
          license_compliance.deny_license denied_license_name
        end

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        wait_for_job "license_management"
      end

      it 'displays license approval status in the pipeline' do
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_on_licenses

          expect(pipeline).to have_license_count_of number_of_licenses_in_fixture
          expect(pipeline).to have_approved_license approved_license_name
          expect(pipeline).to have_blacklisted_license denied_license_name
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
  end
end
