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

      before do
        # Add two new users to a project as members
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @user = create_or_use_existing_user(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
        @user2 = create_or_use_existing_user(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)

        @project = Resource::Project.fabricate! do |project|
          project.name = "codeowners"
        end
        @project.visit!

        Page::Project::Menu.perform(&:click_members_settings)
        Page::Project::Settings::Members.perform do |members_page|
          members_page.add_member(@user.username)
          members_page.add_member(@user2.username)
        end
      end

      it 'displays owners specified in CODEOWNERS file' do
        codeowners_file_content =
          <<-CONTENT
            * @#{@user2.username}
            *.txt @#{@user.username}
          CONTENT
        files << {
          name: 'CODEOWNERS',
          content: codeowners_file_content
        }

        # Push CODEOWNERS and test files to the project
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.files = files
          push.commit_message = 'Add CODEOWNERS and test files'
        end
        Page::Project::Show.perform do |project_page|
          project_page.wait_for_push
        end

        # Check the files and code owners
        Page::Project::Show.perform do |project_page|
          project_page.go_to_file 'file.txt'
        end

        expect(page).to have_content(@user.name)
        expect(page).not_to have_content(@user2.name)

        @project.visit!
        Page::Project::Show.perform do |project_page|
          project_page.go_to_file 'README.md'
        end

        expect(page).to have_content(@user2.name)
        expect(page).not_to have_content(@user.name)
      end

      def create_or_use_existing_user(username, password)
        if Runtime::Env.signup_disabled?
          Resource::User.new.tap do |user|
            user.username = username
            user.password = password
          end
        else
          Resource::User.fabricate!
        end
      end
    end
  end
end
