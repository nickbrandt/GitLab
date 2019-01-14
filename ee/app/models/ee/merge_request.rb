# frozen_string_literal: true

module EE
  module MergeRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include ::Approvable
    include ::Gitlab::Utils::StrongMemoize
    prepend ApprovableForRule

    prepended do
      include Elastic::MergeRequestsSearch

      has_many :reviews, inverse_of: :merge_request
      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approved_by_users, through: :approvals, source: :user
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_users, through: :approvers, source: :user
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approval_rules, class_name: 'ApprovalMergeRequestRule'
      has_many :draft_notes

      validate :validate_approvals_before_merge, unless: :importing?
      validate :validate_approval_rule_source

      delegate :sha, to: :head_pipeline, prefix: :head_pipeline, allow_nil: true
      delegate :sha, to: :base_pipeline, prefix: :base_pipeline, allow_nil: true
      delegate :merge_requests_author_approval?, to: :target_project, allow_nil: true

      participant :participant_approvers

      accepts_nested_attributes_for :approval_rules, allow_destroy: true
    end

    override :mergeable?
    def mergeable?(skip_ci_check: false)
      return false unless approved?

      super
    end

    def supports_weight?
      false
    end

    def validate_approvals_before_merge
      return true unless approvals_before_merge
      return true unless target_project

      # Ensure per-merge-request approvals override is valid
      if approvals_before_merge >= target_project.approvals_before_merge
        true
      else
        errors.add :validate_approvals_before_merge,
                   'Number of approvals must be at least that of approvals on the target project'
      end
    end

    def validate_approval_rule_source
      return unless approval_rules.any?

      local_project_rule_ids = approval_rules.map { |rule| rule.approval_merge_request_rule_source&.approval_project_rule_id }
      local_project_rule_ids.compact!

      invalid = if new_record?
                  local_project_rule_ids.to_set != project.approval_rule_ids.to_set
                else
                  (local_project_rule_ids - project.approval_rule_ids).present?
                end

      errors.add(:approval_rules, :invalid_sourcing_to_project_rules) if invalid
    end

    def participant_approvers
      strong_memoize(:participant_approvers) do
        next [] unless approval_needed?

        if ::Feature.enabled?(:approval_rules, project)
          approval_state.filtered_approvers(code_owner: false, unactioned: true)
        else
          approvers = [
            *overall_approvers(exclude_code_owners: true),
            *approvers_from_groups
          ]

          ::User.where(id: approvers.map(&:id)).where.not(id: approved_by_users.select(:id))
        end
      end
    end

    def code_owners
      strong_memoize(:code_owners) do
        ::Gitlab::CodeOwners.for_merge_request(self).freeze
      end
    end

    def has_license_management_reports?
      actual_head_pipeline&.has_license_management_reports?
    end

    def compare_license_management_reports
      unless has_license_management_reports?
        return { status: :error, status_reason: 'This merge request does not have license management reports' }
      end

      compare_reports(::Ci::CompareLicenseManagementReportsService)
    end

    def sync_code_owners_with_approvers
      return if merged?

      owners = code_owners

      if owners.present?
        ActiveRecord::Base.transaction do
          rule = approval_rules.code_owner.first
          rule ||= approval_rules.code_owner.create!(name: ApprovalMergeRequestRule::DEFAULT_NAME_FOR_CODE_OWNER)

          rule.users = code_owners.uniq
        end
      else
        approval_rules.code_owner.delete_all
      end
    end
  end
end
