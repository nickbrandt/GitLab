# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        class Menu < ::QA::Page::Base
          include QA::Page::Project::SubMenus::Common
          view 'ee/app/views/layouts/nav/_project_insights_link.html.haml' do
            element :project_insights_link
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
