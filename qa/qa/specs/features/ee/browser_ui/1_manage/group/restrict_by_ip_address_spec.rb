# frozen_string_literal: true
require 'securerandom'
require 'socket'

module QA
  # https://gitlab.com/gitlab-org/gitlab/issues/34351
  context 'Manage', :quarantine do
    describe 'Group access' do
      LOOPBACK_ADDRESS = '127.0.0.1'

      before(:all) do
        @sandbox_group = Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = 'gitlab-qa-ip-restricted-sandbox-group'
        end

        @user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

        @group = Resource::Group.fabricate_via_api! do |group|
          group.path = "ip-address-restricted-group-#{SecureRandom.hex(8)}"
          group.sandbox = @sandbox_group
        end
      end

      before do
        Page::Main::Menu.perform do |menu|
          menu.sign_out if menu.has_personal_area?(wait: 0)
        end

        Flow::Login.sign_in
      end

      context 'when restricted by another ip address' do
        it 'denies access' do
          @group.sandbox.visit!

          Page::Group::Menu.perform(&:click_group_general_settings_item)

          Page::Group::Settings::General.perform do |settings|
            settings.set_ip_address_restriction(get_next_ip_address)
          end

          Page::Main::Menu.perform do |menu|
            menu.sign_out if menu.has_personal_area?(wait: 0)
          end

          Page::Main::Login.perform do |menu|
            menu.sign_in_using_credentials(user: @user)
          end

          @group.sandbox.visit!
          expect(page).to have_text('Page Not Found')
          page.go_back

          @group.visit!
          expect(page).to have_text('Page Not Found')
          page.go_back
        end
      end

      context 'when restricted by user\'s ip address' do
        it 'allows access' do
          @group.sandbox.visit!

          Page::Group::Menu.perform(&:click_group_general_settings_item)

          Page::Group::Settings::General.perform do |settings|
            settings.set_ip_address_restriction(get_current_ip_address)
          end

          Page::Main::Menu.perform do |menu|
            menu.sign_out if menu.has_personal_area?(wait: 0)
          end

          Page::Main::Login.perform do |menu|
            menu.sign_in_using_credentials(user: @user)
          end

          @group.sandbox.visit!
          expect(page).to have_text(@group.sandbox.path)

          @group.visit!
          expect(page).to have_text(@group.path)
        end
      end

      def get_current_ip_address
        return LOOPBACK_ADDRESS if page.current_host.include?('localhost')

        Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address
      end

      def get_next_ip_address
        current_ip = get_current_ip_address

        QA::Runtime::Logger.info "User's ip address: #{current_ip}"

        current_last_part = current_ip.split(".").pop.to_i

        updated_last_part = current_last_part < 255 ? current_last_part + 1 : 1

        current_ip.split(".")[0...-1].push(updated_last_part).join(".")
      end
    end
  end
end
