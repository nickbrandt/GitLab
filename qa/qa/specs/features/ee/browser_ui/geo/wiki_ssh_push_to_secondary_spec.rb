# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab wiki SSH push to secondary' do
      wiki_title = 'Geo Replication Wiki'
      wiki_content = 'This tests replication of wikis via SSH to secondary'
      push_content = 'This is from the Geo wiki push via SSH to secondary!'
      project_name = "geo-wiki-project-#{SecureRandom.hex(8)}"
      key_title = "key for ssh tests #{Time.now.to_f}"
      wiki = nil
      key = nil

      before do
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          # Create a new SSH key
          key = Resource::SSHKey.fabricate! do |resource|
            resource.title = key_title
          end

          # Create a new project and wiki
          project = Resource::Project.fabricate_via_api! do |project|
            project.name = project_name
            project.description = 'Geo project for wiki ssh spec'
          end

          wiki = Resource::Wiki.fabricate! do |wiki|
            wiki.project = project
            wiki.title = wiki_title
            wiki.content = wiki_content
            wiki.message = 'First commit'
          end

          validate_content(wiki_content)
        end
      end

      it 'proxies wiki commit to primary node and ultmately replicates to secondary node' do
        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          EE::Page::Main::Banner.perform do |banner|
            expect(banner).to have_secondary_read_only_banner
          end

          # Ensure the SSH key has replicated
          Page::Main::Menu.perform(&:click_settings_link)
          Page::Profile::Menu.perform(&:click_ssh_keys)

          Page::Profile::SSHKeys.perform do |ssh|
            expect(ssh.keys_list).to have_content(key_title)
            expect(ssh.keys_list).to have_content(key.md5_fingerprint)
          end

          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(project_name)
            dashboard.go_to_project(project_name)
          end

          Page::Project::Menu.perform(&:click_wiki)

          # Grab the SSH URI for the secondary node and store as 'secondary_location'
          Page::Project::Wiki::Show.perform do |show|
            show.wait_for_repository_replication
            show.click_clone_repository
          end

          secondary_location = Page::Project::Wiki::GitAccess.perform do |git_access|
            git_access.choose_repository_clone_ssh
            git_access.repository_location
          end

          # Perform a git push over SSH to the secondary node
          push = Resource::Repository::WikiPush.fabricate! do |push|
            push.ssh_key = key
            push.wiki = wiki
            push.repository_ssh_uri = secondary_location.uri
            push.file_name = 'Home.md'
            push.file_content = push_content
            push.commit_message = 'Update Home.md'
          end

          # Remove ssh:// from the URI to ensure we can match accurately
          # as ssh:// can appear depending on how GitLab is configured.
          ssh_uri = wiki.repository_ssh_location.git_uri.to_s.gsub(%r{ssh://}, '')

          expect(push.output).to match(%r{We'll help you by proxying this.*request to the primary:.*#{ssh_uri}}m)

          # Validate git push worked and new content is visible
          Page::Project::Menu.perform(&:click_wiki)

          Page::Project::Wiki::Show.perform do |show|
            show.wait_for_repository_replication_with(push_content)
            show.refresh
          end

          validate_content(push_content)
        end
      end

      def validate_content(content)
        Page::Project::Wiki::Show.perform do |show|
          expect(show.wiki_text).to have_content(content)
        end
      end
    end
  end
end
