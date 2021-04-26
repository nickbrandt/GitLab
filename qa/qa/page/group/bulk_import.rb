# frozen_string_literal: true

module QA
  module Page
    module Group
      class BulkImport < Page::Base
        view "app/assets/javascripts/import_entities/import_groups/components/import_table.vue" do
          element :import_group_table
        end

        view "app/assets/javascripts/import_entities/import_groups/components/import_table_row.vue" do
          element :import_item
          element :target_namespace_selector_dropdown
          element :import_status_indicator
          element :import_group_button
        end

        # Wait until list of groups has been loaded
        #
        # @return [void]
        def wait_for_groups_to_load
          has_element?(:import_group_table)
        end

        # Import source group in to target group
        #
        # @param [String] source_group_name
        # @param [String] target_group_name
        # @return [Boolean]
        def import_group(source_group_name, target_group_name)
          source_group = all_elements(:import_item, minimum: 1).detect { |el| el.has_text?(source_group_name) }
          raise("Import entry for #{source_group_name} not found!") unless source_group

          within(source_group) do
            click_element(:target_namespace_selector_dropdown)
            find_button(target_group_name).click
            click_element(:import_group_button)

            wait_until(sleep_interval: 0.5, reload: false, raise_on_failure: false) do
              find_element(:import_status_indicator).text == "Complete"
            end
          end
        end
      end
    end
  end
end
