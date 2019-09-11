# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module Project
            def self.included(base)
              base.class_eval do
                view 'ee/app/views/layouts/nav/_project_insights_link.html.haml' do
                  element :project_insights_link
                end
              end
            end

            def click_project_insights_link
              within_sidebar do
                click_element(:project_insights_link)
              end
            end
          end
        end
      end
    end
  end
end
