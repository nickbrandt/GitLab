# frozen_string_literal: true
require 'securerandom'

module QA
  context 'Manage' do
    describe 'Group access', :requires_admin do
      include Runtime::IPAddress

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

      after(:all) do
        @group.remove_via_api!
      end

      context 'when restricted by another ip address' do
        it 'denies access' do
          Flow::Login.while_signed_in_as_admin do
            @group.sandbox.visit!

            Page::Group::Menu.perform(&:click_group_general_settings_item)

            Page::Group::Settings::General.perform do |settings|
              settings.set_ip_address_restriction(get_next_ip_address(fetch_current_ip_address))
            end
          end

          Flow::Login.sign_in(as: @user)

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
          Flow::Login.while_signed_in_as_admin do
            @group.sandbox.visit!

            Page::Group::Menu.perform(&:click_group_general_settings_item)

            Page::Group::Settings::General.perform do |settings|
              settings.set_ip_address_restriction(fetch_current_ip_address)
            end
          end

          Flow::Login.sign_in(as: @user)

          @group.sandbox.visit!
          expect(page).to have_text(@group.sandbox.path)

          @group.visit!
          expect(page).to have_text(@group.path)
        end
      end

      def get_next_ip_address(current_ip_address)
        current_last_part = current_ip_address.split(".").pop.to_i

        updated_last_part = current_last_part < 255 ? current_last_part + 1 : 1

        current_ip_address.split(".")[0...-1].push(updated_last_part).join(".")
      end
    end
  end
end
