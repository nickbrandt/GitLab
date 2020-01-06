# frozen_string_literal: true

module QA
  module EE
    module Page
      module MergeRequest
        module Show
          include Page::Component::LicenseManagement

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
                element :unresolve_review_discussion_checkbox
                element :resolve_review_discussion_checkbox
                element :start_review
                element :comment_now
              end

              view 'ee/app/assets/javascripts/batch_comments/components/preview_dropdown.vue' do
                element :review_preview_toggle
              end

              view 'ee/app/views/projects/merge_requests/_code_owner_approval_rules.html.haml' do
                element :approver
                element :approver_list
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/grouped_security_reports_app.vue' do
                element :vulnerability_report_grouped
                element :sast_scan_report
                element :dependency_scan_report
                element :container_scan_report
                element :dast_scan_report
              end

              view 'app/assets/javascripts/reports/components/report_section.vue' do
                element :expand_report_button
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/components/approvals/approvals.vue' do
                element :approve_button
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/components/approvals/approvals_summary.vue' do
                element :approvals_summary_content
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue' do
                element :merge_immediately_button
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/modal.vue' do
                element :vulnerability_modal_content
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/event_item.vue' do
                element :event_item_content
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/modal_footer.vue' do
                element :resolve_split_button
                element :create_issue_button
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/dismiss_button.vue' do
                element :dismiss_with_comment_button
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/dismissal_comment_box_toggle.vue' do
                element :dismiss_comment_field
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/dismissal_comment_modal_footer.vue' do
                element :add_and_dismiss_button
              end
            end
          end

          def wait_for_license_compliance_report
            wait(reload: false) do
              has_no_text?('Loading License Compliance report')
            end
          end

          def approvals_required_from
            approvals_content.match(/approvals? from (.*)/)[1]
          end

          def approved?
            approvals_content =~ /Merge request approved/
          end

          def approvers
            within_element :approver_list do
              all_elements(:approver).map { |item| item.find('img')['title'] }
            end
          end

          def click_approve
            click_element :approve_button

            find_element :approve_button, text: "Revoke approval"
          end

          def start_review
            click_element :start_review

            # After clicking the button, wait for it to disappear
            # before moving on to the next part of the test
            has_no_element? :start_review
          end

          def comment_now
            click_element :comment_now

            # After clicking the button, wait for it to disappear
            # before moving on to the next part of the test
            has_no_element? :comment_now
          end

          def submit_pending_reviews
            within_element :review_bar do
              click_element :review_preview_toggle
              click_element :submit_review

              # After clicking the button, wait for it to disappear
              # before moving on to the next part of the test
              has_no_element? :submit_review
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
            check_element :resolve_review_discussion_checkbox
          end

          def unresolve_review_discussion
            check_element :unresolve_review_discussion_checkbox
          end

          def expand_license_report
            within_element(:license_report_widget) do
              click_element(:expand_report_button)
            end
          end

          def license_report_expanded?
            within_element(:license_report_widget) do
              has_element?(:expand_report_button, text: "Collapse")
            end
          end

          def approve_license_with_mr(name)
            expand_license_report unless license_report_expanded?
            approve_license(name)
          end

          def blacklist_license_with_mr(name)
            expand_license_report unless license_report_expanded?
            blacklist_license(name)
          end

          def expand_vulnerability_report
            within_element :vulnerability_report_grouped do
              click_element :expand_report_button unless has_content? 'Collapse'
            end
          end

          def click_vulnerability(name)
            within_element :vulnerability_report_grouped do
              click_on name
            end

            wait(reload: false) do
              find_element(:vulnerability_modal_content)[:class].include? 'show'
            end
          end

          def dismiss_vulnerability_with_reason(name, reason)
            expand_vulnerability_report
            click_vulnerability(name)
            click_element :dismiss_with_comment_button
            find_element(:dismiss_comment_field).fill_in with: reason
            click_element :add_and_dismiss_button

            wait(reload: false) do
              has_no_element?(:vulnerability_modal_content)
            end
          end

          def resolve_vulnerability_with_mr(name)
            expand_vulnerability_report
            click_vulnerability(name)

            previous_page = page.current_url
            click_element :resolve_split_button

            wait(max: 15, reload: false) do
              page.current_url != previous_page
            end
          end

          def create_vulnerability_issue(name)
            expand_vulnerability_report
            click_vulnerability(name)

            previous_page = page.current_url
            click_element(:create_issue_button)

            wait(max: 15, reload: false) do
              page.current_url != previous_page
            end
          end

          def has_vulnerability_report?(timeout: 60)
            wait(reload: true, max: timeout, interval: 1) do
              finished_loading?
              has_element?(:vulnerability_report_grouped, wait: 10)
            end
            find_element(:vulnerability_report_grouped).has_no_content?("is loading")
          end

          def has_vulnerability_count?
            # Match text cut off in order to find both "1 vulnerability" and "X vulnerabilities"
            find_element(:vulnerability_report_grouped).has_content?(/Security scanning detected/)
          end

          def has_sast_vulnerability_count_of?(expected)
            find_element(:sast_scan_report).has_content?(/SAST detected #{expected}( new)? vulnerabilit/)
          end

          def has_dependency_vulnerability_count_of?(expected)
            find_element(:dependency_scan_report).has_content?(/Dependency scanning detected #{expected}( new)? vulnerabilit/)
          end

          def has_container_vulnerability_count_of?(expected)
            find_element(:container_scan_report).has_content?(/Container scanning detected #{expected}( new)? vulnerabilit/)
          end

          def has_dast_vulnerability_count?
            find_element(:dast_scan_report).has_content?(/DAST detected \d*( new)? vulnerabilit/)
          end

          def has_opened_dismissed_vulnerability?(reason = nil)
            within_element(:vulnerability_modal_content) do
              dismissal_found = has_element?(:event_item_content, text: /Dismissed on pipeline #\d+/)

              if dismissal_found && reason
                dismissal_found = has_element?(:event_item_content, text: reason)
              end

              dismissal_found
            end
          end

          def num_approvals_required
            approvals_content.match(/Requires (\d+) more approvals/)[1].to_i
          end

          def skip_merge_train_and_merge_immediately
            click_element :merge_moment_dropdown
            click_element :merge_immediately_option

            # Wait for the warning modal dialog to appear
            wait_for_animated_element :merge_immediately_button

            click_element :merge_immediately_button
          end

          def merge_via_merge_train
            raise ElementNotFound, "Not ready to merge" unless ready_to_merge?

            click_element(:merge_button, text: "Start merge train")
          end

          private

          def approvals_content
            # The approvals widget displays "Checking approval status" briefly
            # while loading the widget, so before returning the text we wait
            # for it to include terms from content we expect. The kinds
            # of content we expect are:
            #
            # * Requires X more approvals from Quality, UX, and frontend.
            # * Merge request approved
            #
            # It can also briefly display cached data while loading so we
            # wait for it to update first
            sleep 1

            text = nil
            wait(reload: false) do
              text = find_element(:approvals_summary_content).text
              text =~ /Requires|approved/
            end

            text
          end
        end
      end
    end
  end
end
