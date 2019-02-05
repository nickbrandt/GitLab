# frozen_string_literal: true

module MergeRequests
  class SyncCodeOwnerApprovalRules
    def initialize(merge_request, params = {})
      @merge_request = merge_request
      @previous_diff = params[:previous_diff]
    end

    def execute
      if ::Feature.enabled?(:multiple_code_owner_rules)
        sync_rules
      else
        merge_request.sync_code_owners_with_approvers
      end
    end

    private

    attr_reader :merge_request, :previous_diff

    def sync_rules
      return if merge_request.merged?

      delete_outdated_code_owner_rules

      existing_rules = merge_request.approval_rules.matching_pattern(patterns).to_a

      code_owner_entries.each do |entry|
        rule = existing_rules.detect { |rule| rule.name == entry.pattern }
        rule ||= create_rule(entry)

        rule.users = entry.users
        rule.save
      end
    end

    def create_rule(entry)
      ApprovalMergeRequestRule.find_or_create_code_owner_rule(merge_request, entry.pattern)
    end

    def delete_outdated_code_owner_rules
      merge_request.approval_rules.not_matching_pattern(patterns).delete_all
    end

    def patterns
      @patterns ||= code_owner_entries.map(&:pattern)
    end

    def code_owner_entries
      @code_owner_entries ||= Gitlab::CodeOwners
                                .entries_for_merge_request(merge_request, merge_request_diff: previous_diff)
    end
  end
end
