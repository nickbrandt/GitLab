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
                view 'ee/app/assets/javascripts/related_issues/components/add_issuable_form.vue' do
                  element :add_issue_button
                end

                view 'ee/app/assets/javascripts/related_issues/components/related_issuable_input.vue' do
                  element :add_issue_input
                end

                view 'ee/app/assets/javascripts/related_issues/components/related_issues_block.vue' do
                  element :related_issuable_item
                  element :related_issues_loading_icon
                  element :related_issues_plus_button
                end

                view 'ee/app/assets/javascripts/sidebar/components/weight/weight.vue' do
                  element :weight_label_value
                  element :edit_weight_link
                  element :remove_weight_link
                  element :weight_input_field
                  element :weight_no_value_content
                end

                view 'ee/app/views/projects/issues/_discussion.html.haml' do
                  element :designs_tab_link
                  element :designs_tab_content
                end
              end
            end

            def click_designs_tab
              click_element(:designs_tab_link)
              active_element?(:designs_tab_content)
            end

            def click_remove_weight_link
              click_element(:remove_weight_link)
            end

            def relate_issue(issue)
              click_element(:related_issues_plus_button)
              fill_element(:add_issue_input, issue.web_url)
              send_keys_to_element(:add_issue_input, :enter)
            end

            def related_issuable_item
              find_element(:related_issuable_item)
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
