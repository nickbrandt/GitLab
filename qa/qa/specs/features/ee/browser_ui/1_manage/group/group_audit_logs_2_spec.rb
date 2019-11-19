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

      # Bug issue: https://gitlab.com/gitlab-org/gitlab/issues/14756
      context 'Disable and Enable LFS', :skip do
        before do
          sign_in
          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_lfs_disabled)

          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_lfs_enabled)
        end

        it_behaves_like 'group audit event logs', ["Change lfs enabled from false to true", "Change lfs enabled from true to false"]
      end

      context 'Enable and disable LFS' do
        before do
          sign_in
          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_membership_lock_enabled)

          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_membership_lock_disabled)
        end

        it_behaves_like 'group audit event logs', ["Change membership lock from true to false", "Change membership lock from false to true"]
      end

      context 'Enable and disable allow user request access' do
        before do
          sign_in
          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_request_access_enabled)

          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_request_access_disabled)
        end

        it_behaves_like 'group audit event logs', ["Change request access enabled from true to false", "Change request access enabled from false to true"]
      end

      # Bug issue: https://gitlab.com/gitlab-org/gitlab/issues/31764
      context 'Enable and disable 2FA requirement', :skip do
        before do
          sign_in
          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_require_2fa_enabled)
          Page::Profile::TwoFactorAuth.perform(&:click_configure_it_later_button)

          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_require_2fa_disabled)
        end

        it_behaves_like 'group audit event logs', ["Change require two factor authentication from true to false", "Change require two factor authentication from false to true"]
      end

      context 'Change project creation level' do
        before do
          sign_in
          @group.visit!
          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform do |settings|
            settings.set_project_creation_level("Maintainers")
          end
        end

        it_behaves_like 'group audit event logs', ["Change project creation level"]
      end
    end

    def sign_in
      unless Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end
    end
  end
end
