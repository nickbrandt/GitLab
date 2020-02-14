# frozen_string_literal: true
module EE
  module IssueBoardEntity
    extend ActiveSupport::Concern
    include RequestAwareEntity

    prepended do
      expose :weight, if: ->(issue, _) { issue.supports_weight? }
      expose :blocked do |issue|
        issue.blocked_by_issues.any? { |blocked_by_issue| can?(request.current_user, :read_issue, blocked_by_issue) }
      end
    end
  end
end
