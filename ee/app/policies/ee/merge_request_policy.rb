# frozen_string_literal: true

module EE
  module MergeRequestPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:can_override_approvers, score: 0) do
        @subject.target_project&.can_override_approvers?
      end

      condition(:over_storage_limit, scope: :subject) { @subject.target_project&.namespace&.over_storage_limit? }

      rule { ~can_override_approvers }.prevent :update_approvers
      rule { can?(:update_merge_request) }.policy do
        enable :update_approvers
      end

      rule { over_storage_limit }.policy do
        prevent :approve_merge_request
        prevent :update_merge_request
        prevent :reopen_merge_request
        prevent :create_note
        prevent :resolve_note
      end
    end
  end
end
