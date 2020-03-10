# frozen_string_literal: true

module EE
  module API
    module Entities
      class MergeRequestApprovalRule < ApprovalRule
        expose :source_rule, using: MergeRequestApprovalRule::SourceRule
      end
    end
  end
end
