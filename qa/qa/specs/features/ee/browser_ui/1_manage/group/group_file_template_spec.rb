# frozen_string_literal: true

module QA
  context 'Manage' do
    describe 'Group file templates' do
      include Support::Api

      templates = [
        {
          type: 'Dockerfile',
          template: 'custom_dockerfile',
          file_path: 'Dockerfile/custom_dockerfile.dockerfile',
          content: 'dockerfile template test'
        },
        {
          type: '.gitignore',
          template: 'custom_gitignore',
          file_path: 'gitignore/custom_gitignore.gitignore',
          content: 'gitignore template test'
        },
        {
          type: '.gitlab-ci.yml',
          template: 'custom_gitlab-ci',
          file_path: 'gitlab-ci/custom_gitlab-ci.yml',
          content: 'gitlab-ci template test'
        },
        {
          type: 'LICENSE',
          template: 'custom_license',
          file_path: 'LICENSE/custom_license.txt',
          content: 'license template test'
        }
      ]

      before(:all) do
        login

        @group = Resource::Group.fabricate_via_api! do |group|
          group.path = 'template-group'
        end

        @file_template_project = Resource::Project.fabricate_via_api! do |project|
          project.group = @group
          project.name = 'group-file-template-project'
          project.description = 'Add group file templates'
          project.initialize_with_readme = true
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = @file_template_project
          commit.commit_message = 'Add CODEOWNERS and test files'
          commit.add_files(templates)
        end

        @project = Resource::Project.fabricate_via_api! do |project|
          project.group = @group
          project.name = 'group-file-template-project-2'
          project.description = 'Add files for group file templates'
          project.initialize_with_readme = true
        end

        Page::Main::Menu.perform(&:sign_out)
      end

      after(:all) do
        login unless Page::Main::Menu.perform(&:signed_in?)

        remove_group_file_template_if_set

        Page::Main::Menu.perform(&:sign_out)
      end

      templates.each do |template|
        it "creates file via custom #{template[:type]} file template" do
          login
          set_file_template_if_not_already_set

          @project.visit!

          Page::Project::Show.perform(&:create_new_file!)
          Page::File::Form.perform do |form|
            form.select_template template[:type], template[:template]
          end

          expect(page).to have_content(template[:content])

          Page::File::Form.perform(&:commit_changes)

          expect(page).to have_content('The file has been successfully created.')
          expect(page).to have_content(template[:type])
          expect(page).to have_content('Add new file')
          expect(page).to have_content(template[:content])
        end
      end

      def login
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_admin_credentials)
      end

      def set_file_template_if_not_already_set
        api_client = Runtime::API::Client.new(:gitlab)
        response = get Runtime::API::Request.new(api_client, "/groups/#{@group.id}").url

        if parse_body(response)[:file_template_project_id]
          return
        else
          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)

          Page::Group::Settings::General.perform do |general|
            general.choose_file_template_repository(@file_template_project.name)
          end
        end
      end

      def remove_group_file_template_if_set
        api_client = Runtime::API::Client.new(:gitlab)
        response = get Runtime::API::Request.new(api_client, "/groups/#{@group.id}").url

        if parse_body(response)[:file_template_project_id]
          put Runtime::API::Request.new(api_client, "/groups/#{@group.id}").url, { file_template_project_id: nil }
        end
      end
    end
  end
end
