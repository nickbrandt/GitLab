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

        @user = Factory::Resource::User.fabricate!
        @user2 = Factory::Resource::User.fabricate!

        Page::Main::Menu.perform { |menu| menu.sign_out }
        Page::Main::Login.perform { |login_page| login_page.sign_in_using_credentials }

        @project = Factory::Resource::Project.fabricate! do |project|
          project.name = "codeowners"
        end
        @project.visit!

        Page::Project::Menu.perform { |menu| menu.click_members_settings }
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
        Factory::Repository::ProjectPush.fabricate! do |push|
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
    end
  end
end
