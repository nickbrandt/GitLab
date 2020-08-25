# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :docker, :runner, :requires_admin do
    describe 'Artifacts' do
      context 'when locked' do
        let(:ff_keep_latest) { 'keep_latest_artifacts_for_ref' }
        let(:ff_destroy_unlocked) { 'destroy_only_unlocked_expired_artifacts' }
        let(:file_name) { 'artifact.txt' }
        let(:directory_name) { 'my_artifacts' }
        let(:executor) { "qa-runner-#{Time.now.to_i}" }

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-with-locked-artifacts'
          end
        end

        let!(:runner) do
          Resource::Runner.fabricate! do |runner|
            runner.project = project
            runner.name = executor
            runner.tags = [executor]
          end
        end

        before do
          [ff_keep_latest, ff_destroy_unlocked].each { |flag| Runtime::Feature.enable_and_verify(flag) }
          Flow::Login.sign_in
        end

        after do
          [ff_keep_latest, ff_destroy_unlocked].each { |flag| Runtime::Feature.disable_and_verify(flag) }
          runner.remove_via_api!
        end

        it 'can be browsed' do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files(
              [
                {
                  file_path: '.gitlab-ci.yml',
                  content: <<~YAML
                    test-artifacts:
                      tags:
                        - '#{executor}'
                      artifacts:
                        paths:
                          - '#{directory_name}'
                        expire_in: 1 sec
                      script:
                        - |
                          mkdir #{directory_name}
                          echo "CONTENTS" > #{directory_name}/#{file_name}
                  YAML
                }
              ]
            )
          end.project.visit!

          Page::Project::Menu.perform(&:click_ci_cd_pipelines)
          Page::Project::Pipeline::Index.perform do |index|
            index.wait_for_latest_pipeline_completion
            index.click_on_latest_pipeline
          end

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('test-artifacts')
          end

          Page::Project::Job::Show.perform do |show|
            expect(show).to have_browse_button
            show.click_browse_button
          end

          EE::Page::Project::Artifact::Show.perform do |show|
            show.go_to_directory(directory_name)
            expect(show).to have_content(file_name)
          end
        end
      end
    end
  end
end
