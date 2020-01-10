# frozen_string_literal: true
module EE
  module IssueBoardEntity
    extend ActiveSupport::Concern
    include RequestAwareEntity

    prepended do
      expose :weight, if: ->(issue, _) { issue.supports_weight? }
      expose :blocked do |issue|
        issue.target_issue_links.any? { |link| link.link_type == IssueLink::TYPE_BLOCKS && can?(request.current_user, :read_issue, link.source) }
      end
    end
  end
end
