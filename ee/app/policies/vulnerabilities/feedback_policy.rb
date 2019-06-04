# frozen_string_literal: true

module Vulnerabilities
  class FeedbackPolicy < BasePolicy
    delegate { @subject.project }

    condition(:issue) { @subject.issue? }
    condition(:merge_request) { @subject.merge_request? }
    condition(:dismissal) { @subject.dismissal? }

    rule { issue & ~can?(:create_issue) }.prevent :create_vulnerability_feedback

    rule do
      merge_request &
        (~can?(:create_merge_request_in) | ~can?(:create_merge_request_from))
    end.prevent :create_vulnerability_feedback

    rule { ~dismissal }.prevent :destroy_vulnerability_feedback, :update_vulnerability_feedback
  end
end
