# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class Roadmap < QA::Page::Base
          view 'ee/app/assets/javascripts/roadmap/components/epic_item_details.vue' do
            element :epic_details_cell
          end

          view 'ee/app/assets/javascripts/roadmap/components/epic_item_timeline.vue' do
            element :epic_timeline_cell
          end

          view 'ee/app/assets/javascripts/roadmap/components/roadmap_shell.vue' do
            element :roadmap_shell
          end

          def epic_present?(epic)
            uri = URI(epic.group.web_url)
            group_relative_url = uri.path
            epic_href_selector = "a[href='#{group_relative_url}/-/epics/#{epic.iid}']"

            within_element(:roadmap_shell) do
              find("[data-qa-selector='epic_details_cell'] #{epic_href_selector}") &&
              find("[data-qa-selector='epic_timeline_cell'] #{epic_href_selector}")
            end
          end
        end
      end
    end
  end
end
