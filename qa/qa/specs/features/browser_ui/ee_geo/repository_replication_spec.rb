# frozen_string_literal: true

module QA
  context :geo, :orchestrated, :geo do
    describe 'GitLab Geo repository replication' do
      it 'users pushes code to the primary node' do
        Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
          Page::Main::Login.act { sign_in_using_credentials }

          project = Factory::Resource::Project.fabricate! do |project|
            project.name = 'geo-project'
            project.description = 'Geo test project'
          end

          Factory::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.file_name = 'README.md'
            push.file_content = '# This is Geo project!'
            push.commit_message = 'Add README.md'
          end

          Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
            Page::Main::OAuth.act do
              authorize! if needs_authorization?
            end

            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            Page::Main::Menu.perform do |menu|
              menu.go_to_projects
            end

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)

              dashboard.go_to_project(project.name)
            end

            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication

              expect(page).to have_content 'README.md'
              expect(page).to have_content 'This is Geo project!'
            end
          end
        end
      end
    end
  end
end
