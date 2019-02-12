# frozen_string_literal: true
require 'securerandom'

module QA
  # Failure issue: https://gitlab.com/gitlab-org/quality/nightly/issues/72
  context 'Manage', :quarantine do
    describe 'Group level project template' do
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

      it 'user creates and uses group level project template' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        template_container_group_name = "template-container-group-#{SecureRandom.hex(8)}"

        group = QA::Resource::Group.fabricate! do |group|
          group.path = template_container_group_name
          group.description = 'Template container group'
        end

        template_project = Resource::Project.fabricate! do |project|
          project.name = 'template-project-1'
          project.group = group
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = template_project
          push.files = files
          push.commit_message = 'Add test files'
        end

        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform { |page| page.go_to_group(Runtime::Namespace.sandbox_name) }
        Page::Project::Menu.perform(&:go_to_settings)

        EE::Page::Group::Settings::General.perform do |settings|
          settings.choose_custom_project_template("#{template_container_group_name}")
        end

        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform { |page| page.go_to_group(Runtime::Namespace.sandbox_name) }
        Page::Group::Show.perform(&:go_to_new_project)

        Page::Project::New.perform do |page|
          page.go_to_create_from_template_group_tab

          expect(page.group_template_tab_badge_text).to eq "1"
          expect(page).to have_text(template_container_group_name)
          expect(page).to have_text(template_project.name)

          page.use_template_for_project(template_project.name)
          page.choose_name('Project using group level project template')
          page.add_description('Project using group level project template')
          page.set_visibility('Public')
          page.create_new_project
        end

        Page::Project::Show.perform(&:wait_for_import_success)

        files.each do |file|
          expect(page).to have_content(file[:name])
        end
      end
    end
  end
end
