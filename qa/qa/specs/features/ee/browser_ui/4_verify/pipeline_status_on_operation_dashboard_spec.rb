# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Operations Dashboard' do
      let(:group) { Resource::Group.fabricate_via_api! }
      let!(:runner) do
        Resource::Runner.fabricate_via_api! do |runner|
          runner.token = group.reload!.runners_token
          runner.name = group.name
          runner.tags = [group.name]
          runner.project = project_with_success_run
        end
      end

      let(:project_with_success_run) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-success-run'
          project.group = group
        end
      end

      let(:project_without_ci) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-without-ci'
          project.group = group
        end
      end

      let(:project_with_failed_run) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-failed-run'
          project.group = group
        end
      end

      before do
        Flow::Login.sign_in
        setup_projects
        Page::Main::Menu.perform do |menu|
          menu.go_to_more_dropdown_option(:operations_link)
        end
      end

      after do
        runner.remove_via_api!
        remove_projects_from_dashboard
        remove_projects_from_api
      end

      it 'has many pipelines with appropriate statuses', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/900' do
        add_projects_to_board

        EE::Page::OperationsDashboard.perform do |operation|
          {
            'project-with-success-run' => 'passed',
            'project-with-failed-run' => 'failed',
            'project-without-ci' => nil
          }.each do |project_name, status|
            project = operation.find_project_card_by_name(project_name)

            if project_name == 'project-without-ci'
              expect(project).to have_content('The branch for this project has no active pipeline configuration.')
            else
              expect(operation.pipeline_status(project)).to eq(status)
            end
          end
        end
      end

      private

      def commit_ci_file(project, file, status)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([file])
        end

        wait_for_pipeline(project, status)
      end

      def setup_projects
        commit_ci_file(project_with_success_run, ci_file_with_tag, 'success')
        commit_ci_file(project_with_failed_run, ci_file_failed_run, 'failed')
      end

      def wait_for_pipeline(project, status)
        Support::Waiter.wait_until(sleep_interval: 5) do
          pipelines = project.pipelines
          !pipelines.empty? && pipelines.last[:status] == status
        end
      end

      def add_projects_to_board
        [project_with_success_run, project_without_ci, project_with_failed_run].each do |project|
          EE::Page::OperationsDashboard.perform do |operation|
            operation.add_project(project.name)
            expect(operation).to have_project_card
          end
        end
      end

      def remove_projects_from_dashboard
        EE::Page::OperationsDashboard.perform do |operation|
          operation.remove_all_projects
        end
      end

      def remove_projects_from_api
        [project_with_success_run, project_without_ci, project_with_failed_run].each { |project| project.remove_via_api! }
      end

      def ci_file_with_tag
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            test-success:
              tags: ["#{group.name}"]
              script: echo 'OK'
          YAML
        }
      end

      def ci_file_failed_run
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            test-fail:
              tags: ["#{group.name}"]
              script: exit 1
          YAML
        }
      end
    end
  end
end
