# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Show
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/assets/javascripts/related_issues/components/add_issuable_form.vue' do
                  element :add_issue_button
                end

                view 'ee/app/assets/javascripts/related_issues/components/related_issuable_input.vue' do
                  element :add_issue_input
                end

                view 'ee/app/assets/javascripts/related_issues/components/related_issues_block.vue' do
                  element :related_issues_plus_button
                end

                view 'ee/app/assets/javascripts/related_issues/components/related_issues_list.vue' do
                  element :related_issuable_item
                  element :related_issues_loading_icon
                end

                view 'ee/app/assets/javascripts/sidebar/components/weight/weight.vue' do
                  element :weight_label_value
                  element :edit_weight_link
                  element :remove_weight_link
                  element :weight_input_field
                  element :weight_no_value_content
                end
              end
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
              has_no_element?(:related_issues_loading_icon, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
            end

            def weight_label_value
              find_element(:weight_label_value)
            end

            def weight_no_value_content
              find_element(:weight_no_value_content)
            end

            def wait_for_attachment_replication(image_url, max_wait: Runtime::Geo.max_file_replication_time)
              QA::Runtime::Logger.debug(%Q[#{self.class.name} - wait_for_attachment_replication])
              wait_until_geo_max_replication_time(max_wait: max_wait) do
                asset_exists?(image_url)
              end
            end

            def wait_until_geo_max_replication_time(max_wait: Runtime::Geo.max_file_replication_time)
              wait_until(max_duration: max_wait) { yield }
            end
          end
        end
      end
    end
  end
end
