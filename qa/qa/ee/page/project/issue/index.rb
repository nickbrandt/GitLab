# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Index
            def self.prepended(page)
              page.module_eval do
                view 'app/views/shared/issuable/_search_bar.html.haml' do
                  element :issue_filter_form, /form_tag.+class: 'filter-form / # rubocop:disable QA/ElementWithPattern
                  element :issue_filter_input, /%input.form-control.filtered-search/ # rubocop:disable QA/ElementWithPattern
                end

                view 'ee/app/views/projects/issues/_issue_weight.html.haml' do
                  element :issuable_weight
                end

                view 'ee/app/views/projects/issues/export_csv/_button.html.haml' do
                  element :export_as_csv_button
                end

                view 'ee/app/views/projects/issues/export_csv/_modal.html.haml' do
                  element :export_issues_button
                  element :export_issues_modal
                end
              end
            end

            def click_export_as_csv_button
              click_element(:export_as_csv_button)
            end

            def click_export_issues_button
              click_element(:export_issues_button)
            end

            def export_issues_modal
              find_element(:export_issues_modal)
            end

            def issuable_weight
              find_element(:issuable_weight)
            end

            def wait_for_issue_replication(issue)
              wait do
                filter_by_title(issue.title)

                page.has_content?(issue.title)
              end

              click_issue_link(issue.title)
            end

            def filter_by_title(title)
              page.within('form.filter-form') do
                fill_in class: 'filtered-search', with: title
              end
            end
          end
        end
      end
    end
  end
end
