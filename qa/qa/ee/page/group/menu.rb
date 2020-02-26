# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Menu
          prepend QA::Page::Group::SubMenus::Common

          def self.included(base)
            base.class_eval do
              view 'ee/app/views/groups/ee/_settings_nav.html.haml' do
                element :group_saml_sso_link
                element :ldap_synchronization_link
                element :audit_events_settings_link
              end
              view 'ee/app/views/layouts/nav/ee/_epic_link.html.haml' do
                element :group_epics_link
              end

              view 'ee/app/views/layouts/nav/ee/_security_link.html.haml' do
                element :security_compliance_link
                element :group_secure_submenu
                element :security_dashboard_link
              end

              view 'ee/app/views/layouts/nav/_group_insights_link.html.haml' do
                element :group_insights_link
              end

              view 'app/views/layouts/nav/sidebar/_group.html.haml' do
                element :group_issue_boards_link
                element :group_issues_item
                element :group_sidebar
                element :group_sidebar_submenu
                element :group_settings_item
              end
            end
          end

          def go_to_audit_events_settings
            hover_element(:group_settings_item) do
              within_submenu(:group_sidebar_submenu) do
                click_element(:audit_events_settings_link)
              end
            end
          end

          def go_to_issue_boards
            hover_element(:group_issues_item) do
              within_submenu(:group_issues_sidebar_submenu) do
                click_element(:group_issue_boards_link)
              end
            end
          end

          def go_to_saml_sso_group_settings
            hover_element(:group_settings_item) do
              within_submenu(:group_sidebar_submenu) do
                click_element(:group_saml_sso_link)
              end
            end
          end

          def go_to_ldap_sync_settings
            hover_element(:group_settings_item) do
              within_submenu(:group_sidebar_submenu) do
                click_element(:ldap_synchronization_link)
              end
            end
          end

          def click_group_insights_link
            hover_element(:analytics_link) do
              within_submenu(:analytics_sidebar_submenu) do
                click_element(:group_insights_link)
              end
            end
          end

          def click_group_members_item
            within_sidebar do
              click_element(:group_members_item)
            end
          end

          def click_group_general_settings_item
            hover_element(:group_settings_item) do
              within_submenu(:group_sidebar_submenu) do
                click_element(:general_settings_link)
              end
            end
          end

          def click_group_epics_link
            within_sidebar do
              click_element(:group_epics_link)
            end
          end

          def click_group_security_link
            hover_element(:security_compliance_link) do
              within_submenu(:group_secure_submenu) do
                click_element(:security_dashboard_link)
              end
            end
          end
        end
      end
    end
  end
end
