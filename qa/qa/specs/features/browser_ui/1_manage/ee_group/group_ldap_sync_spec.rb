# frozen_string_literal: true

module QA
  # context 'Manage', :orchestrated, :ldap_tls do
  context 'Manage' do
    describe 'LDAP Group Sync' do
      it 'Has LDAP user synced using group cn method' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        # Login users to create them
        login_logout_users(['enguser3', 'enguser2'])

        create_sandbox_group_with_user(user: 'enguser1', group_name:'Synched-engineering-group')

        EE::Page::Group::Menu.perform(&:go_to_ldap_sync_settings)

        EE::Page::Group::Settings::LDAPSync.perform do |page|
          page.set_sync_method('LDAP Group cn')
          page.set_group_cn('Engineering')
          page.click_add_sync_button
        end

        EE::Page::Group::Menu.perform(&:go_to_members)

        verify_users_synched(['ENG User 2', 'ENG User 3'])

      end

      it 'Has LDAP user synced using user filter method' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        # Login users to create them
        login_logout_users(['hruser3', 'hruser2'])

        create_sandbox_group_with_user(user: 'hruser1', group_name:'Synched-human-resources-group')

        EE::Page::Group::Menu.perform(&:go_to_ldap_sync_settings)

        EE::Page::Group::Settings::LDAPSync.perform do |page|
          page.set_user_filter('(&(objectClass=person)(cn=HR*))')
          page.click_add_sync_button
        end

        EE::Page::Group::Menu.perform(&:go_to_members)

        verify_users_synched(['HR User 2', 'HR User 3'])
      end

      def login_logout_users(users)
        users.each do |user|
          Page::Main::Login.perform do |login_page|
            login_page.sign_in_using_ldap_credentials(username: user, password: 'password')
          end

          Page::Main::Menu.perform do |menu|
            expect(menu).to have_personal_area
          end

          Page::Main::Menu.perform(&:sign_out)
        end
      end

      def create_sandbox_group_with_user(user: nil, group_name: nil)
        Page::Main::Login.perform do |login_page|
          login_page.sign_in_using_ldap_credentials(username: user, password: 'password')
        end

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        Resource::Sandbox.fabricate_via_browser_ui! do |resource|
          resource.path = "#{group_name}-#{SecureRandom.hex(4)}"
        end
      end

      def verify_users_synched(expected_users)
        users_synchronised = false
        EE::Page::Group::Members.perform do |page|
          page.click_sync_now
          users_synchronised = page.with_retry(reload: true) do
            expected_users.map { |user| page.has_content?(user) }.reduce(true) { |a, b| a && b }
          end
        end

        expect(users_synchronised).to be_truthy
      end
    end
  end
end
