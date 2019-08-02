# frozen_string_literal: true

require 'pathname'

module QA
  context 'Secure', :docker do
    describe 'Security Reports in a Merge Request' do
      after do
        Service::Runner.new(@executor).remove!
      end

      before do
        @executor = "qa-runner-#{Time.now.to_i}"

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @project = Resource::Project.fabricate_via_api! do |p|
          p.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          p.description = 'Project with Secure'
          p.initialize_with_readme = true
        end

        Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = @executor
          runner.tags = %w[qa test]
        end

        # Push fixture to generate Secure reports
        @source = Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../../ee/fixtures/secure_premade_reports')
          push.commit_message = 'Create Secure compatible application to serve premade reports'
          push.branch_name = 'secure-mr'
        end

        # Fabricate via browser UI to avoid independent navigation
        Resource::MergeRequest.fabricate_via_browser_ui! do |mr|
          mr.project = @project
          mr.source_branch = 'secure-mr'
          mr.target_branch = 'master'
          mr.source = @source
          mr.target = 'master'
          mr.target_new_branch = false
        end
      end

      it 'displays the Security report in the merge request' do
        Page::MergeRequest::Show.perform do |mergerequest|
          expect(mergerequest).to have_vulnerability_report(timeout: 60)
          expect(mergerequest).to have_detected_vulnerability_count_of "2"
        end
      end
    end
  end
end
