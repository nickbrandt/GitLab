# frozen_string_literal: true

module QA
  context 'Create' do
    # Failure issue: https://gitlab.com/gitlab-org/gitlab/issues/43732
    describe 'Elasticsearch advanced global search with advanced syntax', :orchestrated, :elasticsearch, :requires_admin, :quarantine do
      let(:project_name_suffix) { SecureRandom.hex(8) }
      let(:project_file_name) { 'elasticsearch.rb' }
      let(:project_file_content) { "elasticsearch: #{SecureRandom.hex(8)}" }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.add_name_uuid = false
          project.name = "es-adv-global-search-#{project_name_suffix}"
          project.description = "This is a unique project description #{project_name_suffix}"
        end
      end

      before(:context) do
        QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api! do |es|
          es.user = QA::Resource::User.new.tap do |user|
            user.username = QA::Runtime::User.admin_username
            user.password = QA::Runtime::User.admin_password
          end
          es.api_client = Runtime::API::Client.as_admin
        end

        Runtime::Search.assert_elasticsearch_responding
      end

      before do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = project_file_name
          push.file_content = project_file_content
        end

        Flow::Login.sign_in
      end

      context 'when searching for projects using advanced syntax' do
        it 'searches in the project name', retry: 3 do
          expect_search_to_find_project("es-adv-*#{project_name_suffix}")
        end

        it 'searches in the project description', retry: 3 do
          expect_search_to_find_project("unique +#{project_name_suffix}")
        end
      end

      def expect_search_to_find_project(search_term)
        expect { Runtime::Search.find_project(project, search_term) }.not_to raise_error

        Page::Main::Menu.perform do |menu|
          menu.search_for(search_term)
        end

        Page::Search::Results.perform do |results|
          results.switch_to_projects

          results.retry_on_exception(reload: true, sleep_interval: 10) do
            expect(results).to have_content("Advanced search functionality is enabled")
            expect(results).to have_project(project.name)
          end
        end
      end
    end
  end
end
