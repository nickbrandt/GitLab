# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab HTTP push to secondary' do
      it 'is redirected to the primary and ultimately replicated to the secondary' do
        file_name = 'README.md'
        file_content_primary = 'This is a Geo project!  Commit from primary.'
        file_content_secondary = 'This is a Geo project!  Commit from secondary.'

        Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
          # Visit the primary node and login
          Page::Main::Login.act { sign_in_using_credentials }

          # Create a new Project
          project = Resource::Project.fabricate! do |project|
            project.name = 'geo-project'
            project.description = 'Geo test project'
          end

          # Perform a git push over HTTP directly to the primary
          #
          # This push is required to ensure we have the primary credentials
          # written out to the .netrc
          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.file_name = file_name
            push.file_content = "# #{file_content_primary}"
            push.commit_message = "Add #{file_name}"
          end
          project.visit!

          Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
            # Visit the secondary node and login
            Page::Main::OAuth.act { authorize! if needs_authorization? }

            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            Page::Main::Menu.perform { |menu| menu.go_to_projects }

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Grab the HTTP URI for the secondary and store as 'location'
            location = Page::Project::Show.act do
              choose_repository_clone_http
              repository_location
            end

            # Perform a git push over HTTP at the secondary
            Resource::Repository::Push.fabricate! do |push|
              push.new_branch = false
              push.repository_http_uri = location.uri
              push.file_name = file_name
              push.file_content = "# #{file_content_secondary}"
              push.commit_message = "Update #{file_name}"
            end

            # Validate git push worked and new content is visible
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_content_secondary)
              show.refresh

              expect(page).to have_content(file_name)
              expect(page).to have_content(file_content_secondary)
            end
          end
        end
      end
    end
  end
end
