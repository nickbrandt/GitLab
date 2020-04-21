# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Codeowners' do
      let(:files) do
        [
          {
            name: 'file.txt',
            content: 'foo'
          },
          {
            name: 'README.md',
            content: 'bar'
          }
        ]
      end

      let(:user) do
        Resource::User.fabricate_or_use do |user|
          user.name = Runtime::Env.gitlab_qa_username_1
          user.password = Runtime::Env.gitlab_qa_password_1
        end
      end

      let(:user2) do
        Resource::User.fabricate_or_use do |user2|
          user2.name = Runtime::Env.gitlab_qa_username_2
          user2.password = Runtime::Env.gitlab_qa_password_2
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "codeowners"
        end
      end

      before do
        project.add_member(user)
        project.add_member(user2)
      end

      it 'displays owners specified in CODEOWNERS file' do
        Flow::Login.sign_in
        project.visit!
        codeowners_file_content =
          <<-CONTENT
            * @#{user2.username}
            *.txt @#{user.username}
          CONTENT
        files << {
          name: 'CODEOWNERS',
          content: codeowners_file_content
        }

        # Push CODEOWNERS and test files to the project
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.files = files
          push.commit_message = 'Add CODEOWNERS and test files'
        end
        project.visit!

        # Check the files and code owners
        Page::Project::Show.perform do |project_page|
          project_page.click_file 'file.txt'
        end

        expect(page).to have_content(user.name)
        expect(page).not_to have_content(user2.name)

        project.visit!
        Page::Project::Show.perform do |project_page|
          project_page.click_file 'README.md'
        end

        expect(page).to have_content(user2.name)
        expect(page).not_to have_content(user.name)
      end
    end
  end
end
