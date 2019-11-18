# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Multiple assignees per issue' do
      before do
        Flow::Login.sign_in

        user_1 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
        @user_2 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)

        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'project-to-test-issue-with-multiple-assignees'
        end

        project.add_member(user_1)
        project.add_member(@user_2)

        @issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue.title = 'issue-to-test-multiple-assignees'
          issue.project = project
          issue.assignee_ids = [user_1.id]
        end
      end

      it 'assigns one more user to an issue via the browser UI' do
        @issue.visit!

        Page::Project::Issue::Show.perform do |show|
          show.assign(@user_2)

          show.select_all_activities_filter

          expect(show).to have_content "assigned to @#{@user_2.username}"
          expect(show.avatar_image_count).to be 2
          expect(show.assignee_title).to have_content '2 Assignees'
        end
      end
    end
  end
end
