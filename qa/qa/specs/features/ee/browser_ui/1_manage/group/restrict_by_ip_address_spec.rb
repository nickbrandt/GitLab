# frozen_string_literal: true
require 'securerandom'

module QA
  context 'Manage', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/212544', type: :flaky } do
    describe 'Group access', :requires_admin do
      include Runtime::IPAddress

      before(:all) do
        @sandbox_group = Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "gitlab-qa-ip-restricted-sandbox-group-#{SecureRandom.hex(8)}"
        end

        @user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

        @group = Resource::Group.fabricate_via_api! do |group|
          group.path = "ip-address-restricted-group-#{SecureRandom.hex(8)}"
          group.sandbox = @sandbox_group
        end

        enable_plan_on_group(@sandbox_group.path, "Gold") if Runtime::Env.dot_com?
      end

      after(:all) do
        @sandbox_group.remove_via_api!

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end

      before do
        page.visit Runtime::Scenario.gitlab_address

        set_ip_address_restriction_to(ip_address)

        Flow::Login.sign_in(as: @user)
      end

      context 'when restricted by another ip address' do
        let(:ip_address) { get_next_ip_address(fetch_current_ip_address) }

        it 'denies access' do
          @group.sandbox.visit!
          expect(page).to have_text('Page Not Found')
          page.go_back

          @group.visit!
          expect(page).to have_text('Page Not Found')
          page.go_back
        end
      end

      context 'when restricted by user\'s ip address' do
        let(:ip_address) { fetch_current_ip_address }

        it 'allows access' do
          @group.sandbox.visit!
          expect(page).to have_text(@group.sandbox.path)

          @group.visit!
          expect(page).to have_text(@group.path)
        end
      end

      # TODO - Remove this block when the test is un-quarantined.
      after do |example|
        if example.exception
          @group.sandbox.visit!
          QA::Runtime::Logger.info "On failure - Revisiting: #{@group.sandbox.path}"
          QA::Runtime::Logger.info page.save_screenshot(::File.join(QA::Runtime::Namespace.name, "group_sandbox_on_failure.png"), full: true)

          Flow::Login.while_signed_in_as_admin do
            @group.sandbox.visit!

            Page::Group::Menu.perform(&:click_group_general_settings_item)

            Page::Group::Settings::General.perform do |settings|
              QA::Runtime::Logger.info "On failure - IP address restriction is set to: #{settings.restricted_ip_address}"
              QA::Runtime::Logger.info page.save_screenshot(::File.join(QA::Runtime::Namespace.name, "ip_restriction_on_failure.png"), full: true)
            end
          end
        end
      end

      private

      def set_ip_address_restriction_to(ip_address)
        Flow::Login.while_signed_in_as_admin do
          @group.sandbox.visit!

          Page::Group::Menu.perform(&:click_group_general_settings_item)

          Page::Group::Settings::General.perform do |settings|
            settings.set_ip_address_restriction(ip_address)
          end

          # TODO: On un-quarantine, re-evaluate if this is needed.
          ensure_ip_address_set_to(ip_address)
        end
      end

      def ensure_ip_address_set_to(ip_address)
        @group.sandbox.visit!

        Page::Group::Menu.perform(&:click_group_general_settings_item)

        Page::Group::Settings::General.perform do |settings|
          expect(settings.restricted_ip_address).to eq ip_address
        end
      end

      def get_next_ip_address(current_ip_address)
        current_last_part = current_ip_address.split(".").pop.to_i

        updated_last_part = current_last_part < 255 ? current_last_part + 1 : 1

        current_ip_address.split(".")[0...-1].push(updated_last_part).join(".")
      end

      def enable_plan_on_group(group, plan)
        Flow::Login.while_signed_in_as_admin do
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_groups_overview)

          Page::Admin::Overview::Groups::Index.perform do |index|
            index.search_group(group)
            index.click_group(group)
          end

          Page::Admin::Overview::Groups::Show.perform(&:click_edit_group_link)

          Page::Admin::Overview::Groups::Edit.perform do |edit|
            edit.select_plan(plan)
            edit.click_save_changes_button
          end
        end
      end
    end
  end
end
