# frozen_string_literal: true

module API
  module Entities
    class MergeRequestJiraIssue < Grape::Entity
      expose :issue_keys, if: -> (merge_request, _) { merge_request.project&.project_setting&.prevent_merge_without_jira_issue } do |merge_request|
        Atlassian::JiraIssueKeyExtractor.new(merge_request.title, merge_request.description).issue_keys
      end
    end
  end
end
