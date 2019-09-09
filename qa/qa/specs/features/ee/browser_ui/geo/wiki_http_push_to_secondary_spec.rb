# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab Geo Wiki HTTP push secondary' do
      let(:wiki_content) { 'This tests wiki pushes via HTTP to secondary.' }
      let(:push_content) { 'This is from the Geo wiki push to secondary!' }
      let(:project_name) { "geo-wiki-project-#{SecureRandom.hex(8)}" }

      context 'wiki commit' do
        it 'is redirected to the primary and ultimately replicated to the secondary' do
          wiki = nil

          Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
            # Visit the primary node and login
            Page::Main::Login.perform(&:sign_in_using_credentials)

            # Create a new project and wiki
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = project_name
              project.description = 'Geo test project'
            end

            wiki = Resource::Wiki.fabricate! do |wiki|
              wiki.project = project
              wiki.title = 'Geo wiki'
              wiki.content = wiki_content
              wiki.message = 'First wiki commit'
            end

            expect(wiki).to have_content(wiki_content)
          end

          Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
            # Visit the secondary node and login
            Page::Main::Login.perform(&:sign_in_using_credentials)

            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project_name)
              dashboard.go_to_project(project_name)
            end

            Page::Project::Menu.perform(&:click_wiki)

            # Perform a git push over HTTP at the secondary
            Resource::Repository::WikiPush.fabricate! do |push|
              push.wiki = wiki
              push.file_name = 'Home.md'
              push.file_content = push_content
              push.commit_message = 'Update Home.md'
            end

            # Validate git push worked and new content is visible
            Page::Project::Menu.perform(&:click_wiki)

            Page::Project::Wiki::Show.perform do |show|
              show.wait_for_repository_replication_with(push_content)
              show.refresh

              expect(show).to have_content(push_content)
            end
          end
        end
      end
    end
  end
end
