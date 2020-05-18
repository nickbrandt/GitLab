# frozen_string_literal: true

module Admin
  module PushRulesHelper
    def show_merge_request_approvals_settings?
      Feature.enabled?(:admin_merge_request_approvals_settings) &&
        License.feature_available?(:admin_merge_request_approvers_rules)
    end
  end
end
