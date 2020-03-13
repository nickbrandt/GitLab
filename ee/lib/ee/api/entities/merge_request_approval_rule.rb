# frozen_string_literal: true

module EE
  module API
    module Entities
      class MergeRequestApprovalRule < ApprovalRule
        class SourceRule < Grape::Entity
          expose :approvals_required
        end

        expose :source_rule, using: MergeRequestApprovalRule::SourceRule
      end
    end
  end
end
