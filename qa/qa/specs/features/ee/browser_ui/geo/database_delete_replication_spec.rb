# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab Geo project deletion replication' do
      deleted_project_name = nil
      deleted_project_id = nil

      before do
        Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
          Page::Main::Login.perform(&:sign_in_using_credentials)

          project_to_delete = Resource::Project.fabricate_via_api! do |project|
            project.name = 'delete-this-project'
            project.description = 'Geo project to be deleted'
          end

          deleted_project_name = project_to_delete.name
          deleted_project_id = project_to_delete.id
        end
      end

      it 'replicates deletion of a project to secondary node' do
        Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        EE::Page::Main::Banner.perform do |banner|
          expect(banner).to have_secondary_read_only_banner
        end

        # Confirm replication of project to secondary node
        Page::Main::Menu.perform(&:go_to_projects)

        Page::Dashboard::Projects.perform do |dashboard|
          expect(dashboard.project_created?(deleted_project_name)).to be_truthy
        end

        Page::Dashboard::Projects.perform(&:clear_project_filter)

        # Delete project from primary node via API
        delete_response = delete_project_on_primary(deleted_project_id)
        expect(delete_response).to have_content('202 Accepted')

        # Confirm deletion is replicated to secondary node
        Page::Dashboard::Projects.perform do |dashboard|
          expect(dashboard.project_deleted?(deleted_project_name)).to be_truthy
        end
      end

      def delete_project_on_primary(project_id)
        api_client = Runtime::API::Client.new(:geo_primary)
        delete Runtime::API::Request.new(api_client, "/projects/#{project_id}").url
      end
    end
  end
end
