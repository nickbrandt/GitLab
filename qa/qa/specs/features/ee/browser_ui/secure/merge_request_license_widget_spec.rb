# frozen_string_literal: true

require 'pathname'

module QA
  # https://gitlab.com/gitlab-org/gitlab/issues/36696
  context 'Secure', :docker, :quarantine do
    describe 'License merge request widget' do
      let(:approved_license_name) { "MIT" }
      let(:blacklisted_license_name) { "Zlib" }
      let(:executor) {"qa-runner-#{Time.now.to_i}"}

      after do
        Service::DockerRun::GitlabRunner.new(executor).remove!
      end

      before do
        Flow::Login.sign_in

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'license-widget-project'
          project.description = 'License widget test'
        end

        Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = executor
          runner.tags = %w[qa test]
        end

        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = @project
          project_push.directory = Pathname
            .new(__dir__)
            .join('../../../../../ee/fixtures/secure_license_files')
          project_push.commit_message = 'Create license file'
        end

        @project.visit!
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_success)

        @merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = @project
          mr.source_branch = 'license-management-mr'
          mr.target_branch = 'master'
          mr.target = 'master'
          mr.file_name = 'gl-license-management-report.json'
          mr.file_content =
            <<~FILE_UPDATE
            {
              "licenses": [
                {
                  "count": 1,
                  "name": "WTFPL"
                },
                {
                  "count": 1,
                  "name": "MIT"
                },
                {
                  "count": 1,
                  "name": "Zlib"
                }
              ]
            }
            FILE_UPDATE
          mr.target_new_branch = false
        end

        @project.visit!
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_success)
      end

      it 'manage licenses from the merge request' do
        @merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.approve_license_with_mr(approved_license_name)
          show.blacklist_license_with_mr(blacklisted_license_name)

          expect(show).to have_approved_license approved_license_name
          expect(show).to have_blacklisted_license blacklisted_license_name
        end
      end
    end
  end
end
