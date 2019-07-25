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
                end
              end
            end

            def click_on_security_dashboard
              within_sidebar do
                click_element :link_security_dashboard
              end
            end
          end
        end
      end
    end
  end
end
