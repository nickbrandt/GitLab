# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class Menu < ::QA::Page::Base
          view 'ee/app/views/groups/ee/_settings_nav.html.haml' do
            element :group_saml_sso_link
            element :ldap_synchronization_link
          end

          view 'app/views/layouts/nav/sidebar/_group.html.haml' do
            element :group_sidebar
            element :group_sidebar_submenu
            element :group_settings_item
            element :group_members_item
          end

          view 'ee/app/views/layouts/nav/ee/_epic_link.html.haml' do
            element :group_epics_link
          end

          def go_to_saml_sso_group_settings
            hover_settings do
              within_submenu do
                click_element(:group_saml_sso_link)
              end
            end
          end

          def go_to_ldap_sync_settings
            hover_settings do
              within_submenu do
                click_element(:ldap_synchronization_link)
              end
            end
          end

          def go_to_members
            within_sidebar do
              click_element(:group_members_item)
            end
          end

          def go_to_group_epics
            within_sidebar do
              click_element(:group_epics_link)
            end
          end

          private

          def hover_settings
            within_sidebar do
              find_element(:group_settings_item).hover
              yield
            end
          end

          def within_sidebar
            within_element(:group_sidebar) do
              yield
            end
          end

          def within_submenu
            within_element(:group_sidebar_submenu) do
              yield
            end
          end
        end
      end
    end
  end
end
