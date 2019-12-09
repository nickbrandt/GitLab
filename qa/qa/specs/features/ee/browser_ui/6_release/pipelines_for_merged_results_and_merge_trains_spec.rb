# frozen_string_literal: true

module QA
  context 'Release', :docker do
    describe 'Pipelines for merged results and merge trains' do
      before(:context) do
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'pipelines-for-merged-results-and-merge-trains'
        end
        @executor = "qa-runner-#{Time.now.to_i}"

        Resource::Runner.fabricate_via_api! do |runner|
          runner.project = @project
          runner.name = @executor
          runner.tags = %w[qa test]
        end

        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = @project
          project_push.file_name = '.gitlab-ci.yml'
          project_push.commit_message = 'Add .gitlab-ci.yml'
          project_push.file_content = <<~EOF
            test:
              tags: ["qa"]
              script: echo 'OK'
              only:
              - merge_requests
          EOF
        end
      end

      before do
        Flow::Login.sign_in

        @project.visit!

        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform do |main|
          main.expand_merge_requests_settings do |settings|
            settings.click_pipelines_for_merged_results_checkbox
            settings.click_save_changes
          end
        end
      end

      after(:context) do
        Service::DockerRun::GitlabRunner.new(@executor).remove!
      end

      it 'creates a pipeline with merged results' do
        # Create a branch that will be merged into master
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = @project
          project_push.new_branch = true
          project_push.branch_name = 'merged-results'
        end

        # Create a merge request to merge the branch we just created
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = @project
          merge_request.source_branch = 'merged-results'
          merge_request.no_preparation = true
        end.visit!

        Page::MergeRequest::Show.perform do |show|
          pipeline_passed = Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 5) do
            show.has_pipeline_status?(/Merged result pipeline #\d+ passed/)
          end

          expect(pipeline_passed).to be_truthy, "Expected the merged result pipeline to pass."

          # The default option is to merge via merge train,
          # but that will be covered by another test
          show.merge_immediately
        end

        merged = Page::MergeRequest::Show.perform(&:merged?)

        expect(merged).to be_truthy, "Expected content 'The changes were merged' but it did not appear."
      end

      it 'merges via a merge train' do
        # Create a branch that will be merged into master
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = @project
          project_push.new_branch = true
          project_push.branch_name = 'merge-train'
          project_push.file_name = "another_file.txt"
          project_push.file_content = "merge me"
        end

        # Create a merge request to merge the branch we just created
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = @project
          merge_request.source_branch = 'merge-train'
          merge_request.no_preparation = true
        end.visit!

        Page::MergeRequest::Show.perform do |show|
          pipeline_passed = Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 5) do
            show.has_pipeline_status?(/Merged result pipeline #\d+ passed/)
          end

          expect(pipeline_passed).to be_truthy, "Expected the merged result pipeline to pass."

          show.merge_via_merge_train
        end

        expect(page).to have_content('Added to the merge train', wait: 60)
        expect(page).to have_content('The changes will be merged into master')

        # It's faster to refresh the page than to wait for the UI to
        # automatically refresh, so we reload if the merge status
        # doesn't update quickly.
        merged = Support::Retrier.retry_until(reload_page: page) do
          Page::MergeRequest::Show.perform(&:merged?)
        end

        expect(merged).to be_truthy, "Expected content 'The changes were merged' but it did not appear."
      end
    end
  end
end
