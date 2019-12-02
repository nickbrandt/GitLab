# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Search using Elasticsearch', :orchestrated, :elasticsearch do
      include Runtime::Fixtures

      before do
        project_name = 'testing_elasticsearch_indexing'
        @project_file_name = 'elasticsearch.rb'
        @project_file_content = 'elasticsearch: true'

        Flow::Login.sign_in

        QA::EE::Resource::Settings::Elasticsearch.fabricate_via_browser_ui!

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = project_name
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.file_name = @project_file_name
          push.file_content = @project_file_content
        end.project.visit!
      end

      it 'tests reindexing after push' do
        QA::Page::Main::Menu.perform do |menu|
          menu.search_for(@project_file_content)
        end

        Page::Search::Results.perform do |search|
          search.switch_to_code

          expect(search).to have_file_with_content @project_file_name, @project_file_content
        end
      end

      it 'tests reindexing after webIDE' do
        template = {
            file_name: 'LICENSE',
            name: 'Mozilla Public License 2.0',
            api_path: 'licenses',
            api_key: 'mpl-2.0'
        }
        content = fetch_template_from_api(template[:api_path], template[:api_key])

        Page::Project::Show.perform(&:open_web_ide!)
        Page::Project::WebIDE::Edit.perform do |ide|
          ide.create_new_file_from_template template[:file_name], template[:name]
          ide.commit_changes
        end

        Page::Main::Menu.perform(&:go_to_groups)

        QA::Page::Main::Menu.perform do |menu|
          menu.search_for content[0..33]
        end

        Page::Search::Results.perform do |search|
          search.switch_to_code

          expect(search).to have_file_in_project template[:file_name], @project.name
          expect(search).to have_file_with_content template[:file_name], content[0..33]
        end
      end
    end
  end
end
