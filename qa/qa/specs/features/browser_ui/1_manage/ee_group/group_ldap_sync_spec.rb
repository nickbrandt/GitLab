# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :ldap_tls do
    describe 'LDAP Group Sync' do
      it 'Has LDAP user synced with group' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        # Login and Logout enguser3
        Page::Main::Login.perform do |login_page|
          login_page.sign_in_using_ldap_credentials(username: 'enguser3', password: 'password')
        end

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        Page::Main::Menu.perform(&:sign_out)

        # Login and Logout enguser2
        Page::Main::Login.perform do |login_page|
          login_page.sign_in_using_ldap_credentials(username: 'enguser2', password: 'password')
        end

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        Page::Main::Menu.perform(&:sign_out)

        # Login enguser1
        Page::Main::Login.perform do |login_page|
          login_page.sign_in_using_ldap_credentials(username: 'enguser1', password: 'password')
        end

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        # Create a sand box group
        Factory::Resource::Sandbox.fabricate_via_browser_ui! do |resource|
          resource.path = "Synched-engineering-group-#{SecureRandom.hex(4)}"
        end

        EE::Page::Group::Menu.perform(&:go_to_ldap_sync_settings)

        EE::Page::Group::Settings::LDAPSync.perform do |page|
          page.set_sync_method('LDAP Group cn')
          page.set_group_cn('Engineering')
          page.click_add_sync_button
        end

        EE::Page::Group::Menu.perform(&:go_to_members)

        EE::Page::Group::Members.perform(&:click_sync_now)

        expect(page).to have_content('ENG User 2')
        expect(page).to have_content('ENG User 3')
      end
    end
  end
end
