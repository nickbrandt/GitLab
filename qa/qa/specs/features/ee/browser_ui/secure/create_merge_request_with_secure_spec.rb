# frozen_string_literal: true

require 'pathname'

module QA
  context 'Secure', :docker do
    describe 'Security Reports in a Merge Request' do
      let(:total_vuln_count) { 49 }
      let(:sast_vuln_count) { 33 }
      let(:dependency_scan_vuln_count) { 4 }
      let(:container_scan_vuln_count) { 8 }
      let(:dast_vuln_count) { 4 }

      after do
        Service::DockerRun::GitlabRunner.new(@executor).remove!
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

        merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = @project
          mr.source_branch = 'secure-mr'
          mr.target_branch = 'master'
          mr.source = @source
          mr.target = 'master'
          mr.target_new_branch = false
        end

        @project.visit!
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)
        wait_for_job "dast"

        merge_request.visit!
      end

      it 'displays the Security reports in the merge request' do
        Page::MergeRequest::Show.perform do |mergerequest|
          expect(mergerequest).to have_vulnerability_report(timeout: 60)
          expect(mergerequest).to have_total_vulnerability_count_of(total_vuln_count)

          mergerequest.expand_vulnerability_report

          expect(mergerequest).to have_sast_vulnerability_count_of(sast_vuln_count)
          expect(mergerequest).to have_dependency_vulnerability_count_of(dependency_scan_vuln_count)
          expect(mergerequest).to have_container_vulnerability_count_of(container_scan_vuln_count)
          expect(mergerequest).to have_dast_vulnerability_count_of(dast_vuln_count)
        end
      end

      it 'can create an auto-remediation MR' do
        Page::MergeRequest::Show.perform do |mergerequest|
          vuln_name = "Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js"

          expect(mergerequest).to have_vulnerability_report(timeout: 60)
          mergerequest.resolve_vulnerability_with_mr vuln_name
          expect(mergerequest).to have_title vuln_name
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
end
