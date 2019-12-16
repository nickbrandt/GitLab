# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab SSH push to secondary' do
      let(:file_content_primary) { 'This is a Geo project! Commit from primary.' }
      let(:file_content_secondary) { 'This is a Geo project! Commit from secondary.' }

      context 'regular git commit' do
        it 'is proxied to the primary and ultimately replicated to the secondary' do
          file_name = 'README.md'
          key_title = "key for ssh tests #{Time.now.to_f}"
          project = nil
          key = nil

          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            # Create a new SSH key for the user
            key = Resource::SSHKey.fabricate! do |resource|
              resource.title = key_title
            end

            # Create a new Project
            project = Resource::Project.fabricate! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project'
            end

            # Perform a git push over SSH directly to the primary
            #
            # This push is required to ensure we have the primary credentials
            # written out to the .netrc
            Resource::Repository::ProjectPush.fabricate! do |push|
              push.ssh_key = key
              push.project = project
              push.file_name = file_name
              push.file_content = "# #{file_content_primary}"
              push.commit_message = "Add #{file_name}"
            end
            project.visit!
          end

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            # Ensure the SSH key has replicated
            Page::Main::Menu.perform(&:click_settings_link)
            Page::Profile::Menu.perform do |menu|
              menu.click_ssh_keys
              menu.wait_for_key_to_replicate(key_title)
            end

            expect(page).to have_content(key_title)
            expect(page).to have_content(key.fingerprint)

            # Ensure project has replicated
            Page::Main::Menu.perform(&:go_to_projects)
            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Grab the SSH URI for the secondary and store as 'location'
            location = Page::Project::Show.perform do |project_page|
              project_page.wait_for_repository_replication
              project_page.repository_clone_ssh_location
            end

            # Perform a git push over SSH at the secondary
            push = Resource::Repository::Push.fabricate! do |push|
              push.new_branch = false
              push.ssh_key = key
              push.repository_ssh_uri = location.uri
              push.file_name = file_name
              push.file_content = "# #{file_content_secondary}"
              push.commit_message = "Update #{file_name}"
            end

            # Remove ssh:// from the URI to ensure we can match accurately
            # as ssh:// can appear depending on how GitLab is configured.
            ssh_uri = project.repository_ssh_location.git_uri.to_s.gsub(%r{ssh://}, '')

            expect(push.output).to match(%r{We'll help you by proxying this.*request to the primary:.*#{ssh_uri}}m)

            # Validate git push worked and new content is visible
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_content_secondary)

              expect(page).to have_content(file_content_secondary)
            end
          end
        end
      end

      context 'git-lfs commit' do
        it 'is proxied to the primary and ultimately replicated to the secondary' do
          key_title = "key for ssh tests #{Time.now.to_f}"
          file_name_primary = 'README.md'
          file_name_secondary = 'README_MORE.md'
          project = nil
          key = nil

          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            # Create a new SSH key for the user
            key = Resource::SSHKey.fabricate! do |resource|
              resource.title = key_title
            end

            # Create a new Project
            project = Resource::Project.fabricate! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project'
            end

            # Perform a git push over SSH directly to the primary
            #
            # This push is required to ensure we have the primary credentials
            # written out to the .netrc
            Resource::Repository::Push.fabricate! do |push|
              push.use_lfs = true
              push.ssh_key = key
              push.repository_ssh_uri = project.repository_ssh_location.uri
              push.file_name = file_name_primary
              push.file_content = "# #{file_content_primary}"
              push.commit_message = "Add #{file_name_primary}"
            end
          end

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            # Ensure the SSH key has replicated
            Page::Main::Menu.perform(&:click_settings_link)
            Page::Profile::Menu.perform do |menu|
              menu.click_ssh_keys
              menu.wait_for_key_to_replicate(key_title)
            end

            expect(page).to have_content(key_title)
            expect(page).to have_content(key.fingerprint)

            # Ensure project has replicated
            Page::Main::Menu.perform(&:go_to_projects)
            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Grab the SSH URI for the secondary and store as 'location'
            location = Page::Project::Show.perform do |project_page|
              project_page.wait_for_repository_replication
              project_page.repository_clone_ssh_location
            end

            # Perform a git push over SSH at the secondary
            push = Resource::Repository::Push.fabricate! do |push|
              push.use_lfs = true
              push.new_branch = false
              push.ssh_key = key
              push.repository_ssh_uri = location.uri
              push.file_name = file_name_secondary
              push.file_content = "# #{file_content_secondary}"
              push.commit_message = "Add #{file_name_secondary}"
            end

            ssh_uri = project.repository_ssh_location.git_uri.to_s.gsub(%r{ssh://}, '')
            expect(push.output).to match(%r{We'll help you by proxying this.*request to the primary:.*#{ssh_uri}}m)
            expect(push.output).to match(/Locking support detected on remote "#{location.uri.to_s}"/)

            # Validate git push worked and new content is visible
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_name_secondary)
              show.refresh

              expect(page).to have_content(file_name_secondary)
            end
          end
        end
      end
    end
  end
end
