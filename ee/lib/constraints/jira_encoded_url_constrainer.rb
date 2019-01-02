# frozen_string_literal: true

module Constraints
  class JiraEncodedUrlConstrainer
    def matches?(request)
      request.path.starts_with?('/-/jira') || request.path.include?(Gitlab::Jira::Dvcs::ENCODED_SLASH)
    end
  end
end
