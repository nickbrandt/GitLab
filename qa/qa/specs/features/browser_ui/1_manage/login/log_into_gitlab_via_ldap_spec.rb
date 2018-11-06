# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :ldap_no_tls, :ldap_tls do
    describe 'LDAP login' do
      it 'Logins with LDAP and syncs admin users' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform do |login_page|
          login_page.sign_in_using_ldap_credentials(username: 'adminuser1', password: 'password')
        end

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area

          # The ldap_sync_worker_cron job is set to run every minute
          admin_synchronised = menu.wait(max: 65, time: 1, reload: true) do
            menu.has_admin_area_link?
          end

          expect(admin_synchronised).to be_truthy
        end
      end
    end
  end
end
