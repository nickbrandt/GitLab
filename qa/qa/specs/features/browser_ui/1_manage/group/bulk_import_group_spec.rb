# frozen_string_literal: true

module QA
  RSpec.describe "Manage", :requires_admin do
    describe "Group bulk import" do
      let!(:api_client) { Runtime::API::Client.as_admin }
      let!(:user) { Resource::User.fabricate_via_api! { |usr| usr.api_client = api_client } }
      let!(:personal_access_token) { Runtime::API::Client.new(user: user).personal_access_token }

      let(:source_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:target_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
          group.path = "target-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:imported_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = target_group
          group.path = source_group.path
        end
      end

      before do
        Runtime::Feature.enable(:bulk_import)

        source_group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        target_group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Flow::Login.sign_in(as: user)
        Page::Main::Menu.new.go_to_import_group
        Page::Group::New.new.connect_gitlab_instance(Runtime::Scenario.gitlab_address, personal_access_token)
      end

      it "performs bulk group import from another gitlab instance" do
        import = Page::Group::BulkImport.perform do |import_page|
          import_page.wait_for_groups_to_load
          import_page.import_group(source_group.path, target_group.path)
        end

        aggregate_failures do
          expect(import).to be_truthy, "Group bulk import did not finish successfully"
          expect(imported_group.path).to eq(source_group.path)
        end
      end

      after do
        Runtime::Feature.disable(:bulk_import)

        source_group&.remove_via_api!
        target_group&.remove_via_api!

        # Imported group might not be immediately removed and 'user' is sole maintainer, so remove might fail
        QA::Support::Retrier.retry_on_exception do
          user&.remove_via_api!
        end
      end
    end
  end
end
