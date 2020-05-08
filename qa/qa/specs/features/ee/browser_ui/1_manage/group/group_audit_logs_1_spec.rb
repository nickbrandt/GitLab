# frozen_string_literal: true
require 'securerandom'

module QA
  context 'Manage' do
    include Support::Api

    let(:api_client) { Runtime::API::Client.new(:gitlab) }

    shared_examples 'audit event' do |expected_events|
      it 'logs audit events for UI operations' do
        wait_for_audit_events(expected_events, group)

        Page::Group::Menu.perform(&:go_to_audit_events_settings)
        expected_events.each do |expected_event|
          # Sometimes the audit logs are not displayed in the UI
          # right away so a refresh may be needed.
          # https://gitlab.com/gitlab-org/gitlab/issues/119203
          # TODO: https://gitlab.com/gitlab-org/gitlab/issues/195424
          Support::Retrier.retry_on_exception(reload_page: page) do
            expect(page).to have_text(expected_event)
          end
        end
      end
    end

    describe 'Group' do
      before(:all) do
        @group = Resource::Group.fabricate_via_api! do |resource|
          resource.path = "test-group-#{SecureRandom.hex(8)}"
        end
      end

      before do
        @event_count = get_audit_event_count(@group)
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'project-shared-with-group'
        end
      end

      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:group) { @group }

      context 'Add group' do
        let(:group_name) { 'new group' }

        before do
          @event_count = 0
          sign_in
          Resource::Group.fabricate_via_browser_ui! do |group|
            group.name = group_name
          end.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
        end

        it_behaves_like 'audit event', ['Add group'] do
          let(:group) do
            Resource::Group.fabricate_via_api! do |group|
              group.name = group_name
            end
          end
        end
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
        it_behaves_like 'audit event', ['Change repository size limit']
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

        it_behaves_like 'audit event', ['Change name']
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

        it_behaves_like 'audit event', ['Add user access as guest', 'Change access level', 'Remove user access']
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

        it_behaves_like 'audit event', ['Add project access', 'Remove project access']
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

    def get_audit_event_count(group)
      response = get Runtime::API::Request.new(api_client, "/groups/#{group.id}/audit_events").url
      puts response
      parse_body(response).length
    end

    def wait_for_audit_events(expected_events, group)
      new_event_count = @event_count + expected_events.length

      puts "****************"
      puts "New event count #{new_event_count}"

      Support::Retrier.retry_until(max_duration: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME, sleep_interval: 1) do
        current_event_count = get_audit_event_count(group)
        puts "Current event count #{current_event_count}"
        current_event_count == new_event_count
      end
    end
  end
end
