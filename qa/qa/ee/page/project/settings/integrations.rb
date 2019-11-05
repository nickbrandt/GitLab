# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          class Integrations < QA::Page::Base
            view 'app/views/projects/services/_index.html.haml' do
              element :jenkins_ci_link, '{ data: { qa_selector: "#{service.title.downcase.gsub' # rubocop:disable QA/ElementWithPattern
            end

            def click_jenkins_ci_link
              click_element :jenkins_ci_link
            end
          end
        end
      end
    end
  end
end
