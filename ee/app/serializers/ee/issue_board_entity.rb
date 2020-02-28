# frozen_string_literal: true
module EE
  module IssueBoardEntity
    extend ActiveSupport::Concern
    include RequestAwareEntity

    prepended do
      expose :weight, if: ->(issue, _) { issue.supports_weight? }
      expose :blocked do |issue, options|
        options[:blocked_issue_ids].present? && options[:blocked_issue_ids].include?(issue.id)
      end
    end
  end
end
