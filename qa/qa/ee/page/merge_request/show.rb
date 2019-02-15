# frozen_string_literal: true

module QA
  module EE
    module Page
      module MergeRequest
        module Show
          def self.prepended(page)
            page.module_eval do
              view 'app/assets/javascripts/vue_merge_request_widget/components/states/sha_mismatch.vue' do
                element :head_mismatch, "The source branch HEAD has recently changed." # rubocop:disable QA/ElementWithPattern
              end

              view 'ee/app/assets/javascripts/batch_comments/components/publish_button.vue' do
                element :submit_review
              end

              view 'ee/app/assets/javascripts/batch_comments/components/review_bar.vue' do
                element :review_bar
                element :discard_review
                element :modal_delete_pending_comments
              end

              view 'app/assets/javascripts/notes/components/note_form.vue' do
                element :unresolve_review_discussion
                element :resolve_review_discussion
                element :start_review
                element :comment_now
              end

              view 'ee/app/assets/javascripts/batch_comments/components/preview_dropdown.vue' do
                element :review_preview_toggle
              end

              view 'ee/app/views/shared/issuable/_approvals_single_rule.html.haml' do
                element :approver_list
              end

              def start_review
                click_element :start_review
              end

              def comment_now
                click_element :comment_now
              end

              def submit_pending_reviews
                within_element :review_bar do
                  click_element :review_preview_toggle
                  click_element :submit_review
                end
              end

              def discard_pending_reviews
                within_element :review_bar do
                  click_element :discard_review
                end
                click_element :modal_delete_pending_comments
              end

              def resolve_review_discussion
                scroll_to_element :start_review
                check_element :resolve_review_discussion
              end

              def unresolve_review_discussion
                check_element :unresolve_review_discussion
              end
            end
          end
        end
      end
    end
  end
end
