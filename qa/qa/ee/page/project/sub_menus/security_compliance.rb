# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module SecurityCompliance
            include QA::Page::Project::SubMenus::Common

            def self.included(page)
              page.class_eval do
                view 'ee/app/views/layouts/nav/sidebar/_project_security_link.html.haml' do
                  element :link_security_dashboard
                  element :dependency_list_link
                end
              end
            end

            def click_on_security_dashboard
              within_sidebar do
                click_element :link_security_dashboard
              end
            end

            def click_on_dependency_list
              hover_security_compliance do
                within_submenu do
                  click_element(:dependency_list_link)
                end
              end
            end

            def hover_security_compliance
              within_sidebar do
                find_element(:link_security_dashboard).hover

                yield
              end
            end
          end
        end
      end
    end
  end
end
