# frozen_string_literal: true

module API
  module Entities
    class MergeRequestJiraIssue < Grape::Entity
      expose :is_present do |merge_request|
        Atlassian::JiraIssueKeyExtractor.has_keys?(merge_request.title, merge_request.description)
      end
    end
  end
end
