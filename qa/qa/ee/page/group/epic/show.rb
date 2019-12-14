# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Epic
          class Show < QA::Page::Base
            include QA::Page::Component::Issuable::Common

            view 'ee/app/assets/javascripts/epic/components/epic_header.vue' do
              element :close_reopen_epic_button
            end

            view 'ee/app/assets/javascripts/related_issues/components/add_issuable_form.vue' do
              element :add_issue_button
            end

            view 'ee/app/assets/javascripts/related_issues/components/related_issuable_input.vue' do
              element :add_issue_input
            end

            view 'ee/app/assets/javascripts/related_items_tree/components/tree_item.vue' do
              element :related_issue_item
            end

            view 'ee/app/assets/javascripts/related_items_tree/components/tree_item_body.vue' do
              element :remove_issue_button
            end

            view 'ee/app/assets/javascripts/related_issues/constants.js' do
              element :add_issues_button
            end

            def add_issue_to_epic(issue_url)
              click_element :add_issues_button
              fill_element :add_issue_input, issue_url
              click_body
              click_element :add_issue_button
            end

            def add_comment_to_epic(comment)
              fill_element :comment_input, comment
              click_element :comment_button
            end

            def remove_issue_from_epic
              click_element :remove_issue_button
              # Capybara code is used below due to the modal being defined in the @gitlab/ui project
              find('#item-remove-confirmation___BV_modal_footer_ .btn-danger').click
            end

            def click_edit_button
              click_element :edit_button
            end

            def delete_epic
              page.accept_alert("Epic will be removed! Are you sure?") do
                click_element :delete_epic_button
              end
            end

            def close_reopen_epic
              click_element :close_reopen_epic_button
            end

            def has_related_issue_item?
              has_element?(:related_issue_item)
            end

            def has_no_related_issue_item?
              has_no_element?(:related_issue_item)
            end
          end
        end
      end
    end
  end
end
