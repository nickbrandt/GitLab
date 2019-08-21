# frozen_string_literal: true

module EE
  module MergeRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include ::Approvable
    include ::Gitlab::Allowable
    include ::Gitlab::Utils::StrongMemoize
    include FromUnion

    prepended do
      include Elastic::ApplicationVersionedSearch

      has_many :reviews, inverse_of: :merge_request
      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approved_by_users, through: :approvals, source: :user
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_users, through: :approvers, source: :user
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approval_rules, class_name: 'ApprovalMergeRequestRule', inverse_of: :merge_request
      has_many :draft_notes
      has_one :merge_train, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

      has_many :blocks_as_blocker,
               class_name: 'MergeRequestBlock',
               foreign_key: :blocking_merge_request_id

      has_many :blocks_as_blockee,
               class_name: 'MergeRequestBlock',
               foreign_key: :blocked_merge_request_id

      has_many :blocking_merge_requests, through: :blocks_as_blockee

      has_many :blocked_merge_requests, through: :blocks_as_blocker

      delegate :sha, to: :head_pipeline, prefix: :head_pipeline, allow_nil: true
      delegate :sha, to: :base_pipeline, prefix: :base_pipeline, allow_nil: true
      delegate :merge_requests_author_approval?, to: :target_project, allow_nil: true

      participant :participant_approvers

      accepts_nested_attributes_for :approval_rules, allow_destroy: true
    end

    class_methods do
      def select_from_union(relations)
        where(id: from_union(relations))
      end

      # This is an ActiveRecord scope in CE
      def with_api_entity_associations
        super.preload(:blocking_merge_requests)
      end
    end

    override :mergeable?
    def mergeable?(skip_ci_check: false)
      return false unless approved?
      return false if merge_blocked_by_other_mrs?

      super
    end

    def merge_blocked_by_other_mrs?
      strong_memoize(:merge_blocked_by_other_mrs) do
        project.feature_available?(:blocking_merge_requests) &&
          blocking_merge_requests.any? { |mr| !mr.merged? }
      end
    end

    def on_train?
      merge_train.present?
    end

    def allows_multiple_assignees?
      project.feature_available?(:multiple_merge_request_assignees)
    end

    def supports_weight?
      false
    end

    def visible_blocking_merge_requests(user)
      Ability.merge_requests_readable_by_user(blocking_merge_requests, user)
    end

    def visible_blocking_merge_request_refs(user)
      visible_blocking_merge_requests(user).map do |mr|
        mr.to_reference(target_project)
      end
    end

    # Unlike +visible_blocking_merge_requests+, this method doesn't include
    # blocking MRs that have been merged. This simplifies output, since we don't
    # need to tell the user that there are X hidden blocking MRs, of which only
    # Y are an obstacle. Pass include_merged: true to override this behaviour.
    def hidden_blocking_merge_requests_count(user, include_merged: false)
      hidden = blocking_merge_requests - visible_blocking_merge_requests(user)

      hidden.delete_if(&:merged?) unless include_merged

      hidden.count
    end

    def participant_approvers
      strong_memoize(:participant_approvers) do
        next [] unless approval_needed?

        approval_state.filtered_approvers(code_owner: false, unactioned: true)
      end
    end

    def has_dependency_scanning_reports?
      actual_head_pipeline&.has_reports?(::Ci::JobArtifact.dependency_list_reports)
    end

    def compare_dependency_scanning_reports
      unless has_dependency_scanning_reports?
        return { status: :error, status_reason: 'This merge request does not have dependency scanning reports' }
      end

      compare_reports(::Ci::CompareDependencyScanningReportsService)
    end

    def has_license_management_reports?
      actual_head_pipeline&.has_reports?(::Ci::JobArtifact.license_management_reports)
    end

    def has_container_scanning_reports?
      actual_head_pipeline&.has_reports?(::Ci::JobArtifact.container_scanning_reports)
    end

    def compare_container_scanning_reports
      unless has_container_scanning_reports?
        return { status: :error, status_reason: 'This merge request does not have container scanning reports' }
      end

      compare_reports(::Ci::CompareContainerScanningReportsService)
    end

    def has_sast_reports?
      actual_head_pipeline&.has_reports?(::Ci::JobArtifact.sast_reports)
    end

    def compare_sast_reports
      unless has_sast_reports?
        return { status: :error, status_reason: 'This merge request does not have SAST reports' }
      end

      compare_reports(::Ci::CompareSastReportsService)
    end

    def compare_license_management_reports
      unless has_license_management_reports?
        return { status: :error, status_reason: 'This merge request does not have license management reports' }
      end

      compare_reports(::Ci::CompareLicenseManagementReportsService)
    end

    def has_metrics_reports?
      actual_head_pipeline&.has_reports?(::Ci::JobArtifact.metrics_reports)
    end

    def compare_metrics_reports
      unless has_metrics_reports?
        return { status: :error, status_reason: 'This merge request does not have metrics reports' }
      end

      compare_reports(::Ci::CompareMetricsReportsService)
    end
  end
end
