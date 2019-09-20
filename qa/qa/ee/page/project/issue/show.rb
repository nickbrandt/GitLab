# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Show
            include Page::Component::DesignManagement

            def self.prepended(page)
              page.module_eval do
                view 'ee/app/assets/javascripts/related_issues/components/related_issues_block.vue' do
                  element :related_issues_loading_icon
                end

                view 'ee/app/assets/javascripts/sidebar/components/weight/weight.vue' do
                  element :weight_label_value
                  element :edit_weight_link
                  element :remove_weight_link
                  element :weight_input_field
                  element :weight_no_value_content
                end

                view 'ee/app/views/projects/issues/_discussion.html.haml' do
                  element :designs_tab
                end
              end
            end

            def click_designs_tab
              click_element(:designs_tab)
            end

            def click_remove_weight_link
              click_element(:remove_weight_link)
            end

            def set_weight(weight)
              click_element(:edit_weight_link)
              fill_element(:weight_input_field, weight)
              send_keys_to_element(:weight_input_field, :enter)
            end

            def wait_for_related_issues_to_load
              wait(reload: false) do
                has_no_element?(:related_issues_loading_icon)
              end
            end

            def weight_label_value
              find_element(:weight_label_value)
            end

            def weight_no_value_content
              find_element(:weight_no_value_content)
            end
          end
        end
      end
    end
  end
end
