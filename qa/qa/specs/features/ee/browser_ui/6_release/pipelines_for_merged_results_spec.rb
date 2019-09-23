# frozen_string_literal: true

module QA
  context 'Release', :docker do
    describe 'Pipelines for merged results' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pipelines-for-merged-results'
        end
      end
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

      before do
        Resource::Runner.fabricate_via_api! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = %w[qa test]
        end

        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = project
          project_push.file_name = '.gitlab-ci.yml'
          project_push.commit_message = 'Add .gitlab-ci.yml'
          project_push.file_content = <<~EOF
            test:
              script: echo 'OK'
              only:
              - merge_requests
          EOF
        end

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      after do
        Service::Runner.new(executor).remove!
      end

      it 'creates a pipeline with merged results' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_general_settings)

        Page::Project::Settings::Main.perform do |main|
          main.expand_merge_requests_settings do |settings|
            settings.click_pipelines_for_merged_results_checkbox
            settings.click_save_changes
          end
        end

        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
          merge_request.target_new_branch = false
        end.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_pipeline_status(/Merged result pipeline #\d+ passed/)

          # The default option is to merge via merge train,
          # but that will be covered by another test
          merge_request.merge_immediately
        end

        expect(page).to have_content('The changes were merged')
      end
    end
  end
end
