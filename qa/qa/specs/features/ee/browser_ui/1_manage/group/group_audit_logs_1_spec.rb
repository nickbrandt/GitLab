# frozen_string_literal: true
require 'securerandom'

module QA
  context 'Manage' do
    shared_examples 'group audit event logs' do |expected_events|
      it 'logs audit events' do
        Page::Group::Menu.perform(&:go_to_audit_events_settings)
        expected_events.each do |expected_event|
          expect(page).to have_text(expected_event)
        end
      end
    end

    describe 'Group audit logs' do
      before(:all) do
        @group = Resource::Group.fabricate_via_api! do |resource|
          resource.path = "test-group-#{SecureRandom.hex(8)}"
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'project-shared-with-group'
        end
      end

      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }

      context 'Add group' do
        before do
          sign_in
          Resource::Group.fabricate_via_browser_ui!.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
        end

        it_behaves_like 'group audit event logs', ["Add group"]
      end

      context 'Change repository size limit', :requires_admin do
        before do
          sign_in(as_admin: true)
          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform do |settings|
            settings.set_repository_size_limit(100)
            settings.click_save_name_visibility_settings_button
          end
        end
        it_behaves_like 'group audit event logs', ["Change repository size limit"]
      end

      context 'Update group name' do
        before do
          sign_in
          @group.visit!
          updated_group_name = "#{@group.path}-updated"
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform do |settings|
            settings.set_group_name(updated_group_name)
            settings.click_save_name_visibility_settings_button
          end
        end

        it_behaves_like 'group audit event logs', ["Change name"]
      end

      context 'Add user, change access level, remove user' do
        before do
          sign_in
          @group.visit!
          Page::Group::Menu.perform(&:click_group_members_item)
          Page::Group::SubMenus::Members.perform do |members_page|
            members_page.add_member(user.username)
            members_page.update_access_level(user.username, "Developer")
            members_page.remove_member(user.username)
          end
        end

        it_behaves_like 'group audit event logs', ["Add user access as guest", "Change access level", "Remove user access"]
      end

      context 'Add and remove project access' do
        before do
          sign_in
          project.visit!

          Page::Project::Menu.perform(&:go_to_members_settings)
          Page::Project::Settings::Members.perform do |members|
            members.invite_group(@group.path)
          end

          Page::Project::Menu.perform(&:go_to_members_settings)
          Page::Project::Settings::Members.perform do |members|
            members.remove_group(@group.path)
          end

          @group.visit!
        end

        it_behaves_like 'group audit event logs', ["Add project access", "Remove project access"]
      end
    end

    def sign_in(as_admin: false)
      unless Page::Main::Menu.perform(&:signed_in?)
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform do |login|
          as_admin ? login.sign_in_using_admin_credentials : login.sign_in_using_credentials
        end
      end
    end
  end
end
