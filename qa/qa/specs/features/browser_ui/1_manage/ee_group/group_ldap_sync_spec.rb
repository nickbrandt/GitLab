# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :ldap_tls, :ldap_no_tls do
    describe 'LDAP Group sync' do
      before(:all) do
        users = [
            {
                name: 'ENG User 2',
                username: 'enguser2',
                email: 'enguser2@example.org',
                provider: 'ldapmain',
                extern_uid: 'uid=enguser2,ou=people,ou=global groups,dc=example,dc=org'
            },
            {
                name: 'ENG User 3',
                username: 'enguser3',
                email: 'enguser3@example.org',
                provider: 'ldapmain',
                extern_uid: 'uid=enguser3,ou=people,ou=global groups,dc=example,dc=org'
            },
            {
                name: 'HR User 2',
                username: 'hruser2',
                email: 'hruser2@example.org',
                provider: 'ldapmain',
                extern_uid: 'uid=hruser2,ou=people,ou=global groups,dc=example,dc=org'
            },
            {
                name: 'HR User 3',
                username: 'hruser3',
                email: 'hruser3@example.org',
                provider: 'ldapmain',
                extern_uid: 'uid=hruser3,ou=people,ou=global groups,dc=example,dc=org'
            }
        ]
        create_users_via_api(users)
      end

      it 'Has LDAP user synced using group cn method' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        create_group_with_user_via_api(user: 'enguser1', group_name: 'Synched-engineering-group')

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

        create_group_with_user_via_api(user: 'hruser1', group_name: 'Synched-human-resources-group')

        EE::Page::Group::Menu.perform(&:go_to_ldap_sync_settings)

        EE::Page::Group::Settings::LDAPSync.perform do |page|
          page.set_user_filter('(&(objectClass=person)(cn=HR*))')
          page.click_add_sync_button
        end

        EE::Page::Group::Menu.perform(&:go_to_members)

        verify_users_synched(['HR User 2', 'HR User 3'])
      end

      def create_users_via_api(users)
        create_admin_personal_access_token

        users.each do |user|
          Resource::User.fabricate_via_api! do |resource|
            resource.username = user[:username]
            resource.name = user[:name]
            resource.email = user[:email]
            resource.extern_uid = user[:extern_uid]
            resource.provider = user[:provider]
          end
        end
      end

      def create_admin_personal_access_token
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_admin_credentials)
        Runtime::Env.personal_access_token = Resource::PersonalAccessToken.fabricate!.access_token
        Page::Main::Menu.perform(&:sign_out)
      end

      def create_group_with_user_via_api(user: nil, group_name: nil)
        Runtime::Env.ldap_username = user
        Runtime::Env.ldap_password = 'password'

        Page::Main::Login.perform do |login_page|
          login_page.sign_in_using_credentials
        end

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        Runtime::Env.personal_access_token = Resource::PersonalAccessToken.fabricate!.access_token

        group = Resource::Sandbox.fabricate_via_api! do |resource|
          resource.path = "#{group_name}-#{SecureRandom.hex(4)}"
        end

        group.visit!
      end

      def verify_users_synched(expected_users)
        EE::Page::Group::Members.perform do |page|
          page.click_sync_now
          users_synchronised = page.with_retry(reload: true) do
            expected_users.map { |user| page.has_content?(user) }.all?
          end
          expect(users_synchronised).to be_truthy
        end
      end
    end
  end
end
