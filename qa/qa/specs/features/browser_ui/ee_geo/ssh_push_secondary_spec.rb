# frozen_string_literal: true

module QA
  context :geo, :orchestrated, :geo do
    describe 'GitLab Geo SSH push secondary' do
      it "is proxy'd to the primary and ultimately replicated to the secondary" do
        key = nil
        key_title = "key for ssh tests #{Time.now.to_f}"
        file_name = 'README.md'
        file_content_primary = 'This is a Geo project!  Commit from primary.'
        file_content_secondary = 'This is a Geo project!  Commit from secondary.'

        Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
          # Visit the primary node and login
          Page::Main::Login.act { sign_in_using_credentials }

          # Create a new SSH key for the user
          key = Factory::Resource::SSHKey.fabricate! do |resource|
            resource.title = key_title
          end

          # Create a new Project
          project = Factory::Resource::Project.fabricate! do |project|
            project.name = 'geo-project'
            project.description = 'Geo test project'
          end

          # Perform a git push over SSH directly to the primary
          Factory::Repository::Push.fabricate! do |push|
            push.ssh_key = key
            push.repository_ssh_uri = project.repository_ssh_location.uri
            push.file_name = file_name
            push.file_content = "# #{file_content_primary}"
            push.commit_message = 'Add README.md'
          end

          # Validate git push worked and file exists with content
          Page::Project::Show.perform do |show|
            show.wait_for_repository_replication

            expect(page).to have_content(file_name)
            expect(page).to have_content(file_content_primary)
          end

          Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
            # Visit the secondary node and login
            Page::Main::OAuth.act { authorize! if needs_authorization? }

            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            # Ensure the SSH key has replicated
            Page::Main::Menu.act { go_to_profile_settings }
            Page::Profile::Menu.perform do |menu|
              menu.click_ssh_keys
              menu.wait_for_key_to_replicate(key_title)
            end

            expect(page).to have_content(key_title)
            expect(page).to have_content(key.fingerprint)

            # Ensure project has replicated
            Page::Main::Menu.perform { |menu| menu.go_to_projects }
            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Validate the content has been sync'd from the primary
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_content_primary)

              expect(page).to have_content(file_name)
              expect(page).to have_content(file_content_primary)
            end

            # Grab the SSH URI for the secondary and store as 'location'
            location = Page::Project::Show.act do
              choose_repository_clone_ssh
              repository_location
            end

            # Perform a git push over SSH at the secondary
            Factory::Repository::Push.fabricate! do |push|
              push.new_branch = false
              push.ssh_key = key
              push.repository_ssh_uri = location.uri
              push.file_name = file_name
              push.file_content = "# #{file_content_secondary}"
              push.commit_message = 'Update README.md'
            end

            # Validate git push worked and new content is visible
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_content_secondary)

              expect(page).to have_content(file_content_secondary)
            end
          end
        end
      end
    end
  end
end
