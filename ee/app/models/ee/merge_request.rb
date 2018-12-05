# frozen_string_literal: true

module EE
  module MergeRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include ::Approvable
    include ::Gitlab::Utils::StrongMemoize

    prepended do
      include Elastic::MergeRequestsSearch

      has_many :reviews, inverse_of: :merge_request
      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approved_by_users, through: :approvals, source: :user
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approval_rules, class_name: 'ApprovalMergeRequestRule'
      has_many :draft_notes

      validate :validate_approvals_before_merge, unless: :importing?

      delegate :sha, to: :head_pipeline, prefix: :head_pipeline, allow_nil: true
      delegate :sha, to: :base_pipeline, prefix: :base_pipeline, allow_nil: true
      delegate :merge_requests_author_approval?, to: :target_project, allow_nil: true

      participant :participant_approvers
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

    def participant_approvers
      strong_memoize(:participant_approvers) do
        next [] unless approval_needed?

        approvers = []
        approvers.concat(overall_approvers(exclude_code_owners: true))
        approvers.concat(approvers_from_groups)

        ::User.where(id: approvers.map(&:id)).where.not(id: approved_by_users.select(:id))
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

    def finalize_approvals
      return unless merged?

      copy_project_approval_rules unless approval_rules.regular.exists?

      approval_rules.each(&:sync_approvals)
    end

    private

    def copy_project_approval_rules
      target_project.approval_rules.each do |project_rule|
        rule = approval_rules.create!(project_rule.attributes.slice('approvals_required', 'name'))
        rule.users = project_rule.users
        rule.groups = project_rule.groups
      end
    end
  end
end
