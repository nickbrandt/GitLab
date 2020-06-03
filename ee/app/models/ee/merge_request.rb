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
      include DeprecatedApprovalsBeforeMerge
      include UsageStatistics

      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approved_by_users, through: :approvals, source: :user
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_users, through: :approvers, source: :user
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approval_rules, class_name: 'ApprovalMergeRequestRule', inverse_of: :merge_request
      has_one :merge_train, inverse_of: :merge_request, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

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

      scope :without_approvals, -> { left_outer_joins(:approvals).where(approvals: { id: nil }) }
      scope :with_approvals, -> { joins(:approvals) }
      scope :approved_by_users_with_ids, -> (*user_ids) do
        with_approvals
          .merge(Approval.with_user)
          .where(users: { id: user_ids })
          .group(:id)
          .having("COUNT(users.id) = ?", user_ids.size)
      end
      scope :approved_by_users_with_usernames, -> (*usernames) do
        with_approvals
          .merge(Approval.with_user)
          .where(users: { username: usernames })
          .group(:id)
          .having("COUNT(users.id) = ?", usernames.size)
      end

      accepts_nested_attributes_for :approval_rules, allow_destroy: true

      scope :order_review_time_desc, -> do
        joins(:metrics)
          .reorder(::Gitlab::Database.nulls_last_order(::MergeRequest::Metrics.review_time_field))
      end

      scope :with_code_review_api_entity_associations, -> do
        preload(
          :author, :approved_by_users, :metrics,
          latest_merge_request_diff: :merge_request_diff_files, target_project: :namespace, milestone: :project)
      end
    end

    class_methods do
      def select_from_union(relations)
        where(id: from_union(relations))
      end

      # This is an ActiveRecord scope in CE
      def with_api_entity_associations
        super.preload(:blocking_merge_requests)
      end

      def sort_by_attribute(method, *args)
        if method.to_s == 'review_time_desc'
          order_review_time_desc
        else
          super
        end
      end

      # Includes table keys in group by clause when sorting
      # preventing errors in postgres
      #
      # Returns an array of arel columns
      def grouping_columns(sort)
        grouping_columns = super
        grouping_columns << ::MergeRequest::Metrics.review_time_field if sort.to_s == 'review_time_desc'
        grouping_columns
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
      merge_train&.active?
    end

    def allows_multiple_assignees?
      project.feature_available?(:multiple_merge_request_assignees)
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

    def enabled_reports
      {
        sast: report_type_enabled?(:sast),
        container_scanning: report_type_enabled?(:container_scanning),
        dast: report_type_enabled?(:dast),
        dependency_scanning: report_type_enabled?(:dependency_scanning),
        license_scanning: report_type_enabled?(:license_scanning)
      }
    end

    def has_dependency_scanning_reports?
      !!(actual_head_pipeline&.has_reports?(::Ci::JobArtifact.dependency_list_reports))
    end

    def compare_dependency_scanning_reports(current_user)
      return missing_report_error("dependency scanning") unless has_dependency_scanning_reports?

      compare_reports(::Ci::CompareDependencyScanningReportsService, current_user)
    end

    def has_license_scanning_reports?
      !!(actual_head_pipeline&.has_reports?(::Ci::JobArtifact.license_scanning_reports))
    end

    def has_container_scanning_reports?
      !!(actual_head_pipeline&.has_reports?(::Ci::JobArtifact.container_scanning_reports))
    end

    def compare_container_scanning_reports(current_user)
      return missing_report_error("container scanning") unless has_container_scanning_reports?

      compare_reports(::Ci::CompareContainerScanningReportsService, current_user)
    end

    def has_sast_reports?
      !!(actual_head_pipeline&.has_reports?(::Ci::JobArtifact.sast_reports))
    end

    def has_secret_detection_reports?
      !!(actual_head_pipeline&.has_reports?(::Ci::JobArtifact.secret_detection_reports))
    end

    def compare_sast_reports(current_user)
      return missing_report_error("SAST") unless has_sast_reports?

      compare_reports(::Ci::CompareSastReportsService, current_user)
    end

    def compare_secret_detection_reports(current_user)
      return missing_report_error("secret detection") unless has_secret_detection_reports?

      compare_reports(::Ci::CompareSecretDetectionReportsService, current_user)
    end

    def has_dast_reports?
      !!(actual_head_pipeline&.has_reports?(::Ci::JobArtifact.dast_reports))
    end

    def compare_dast_reports(current_user)
      return missing_report_error("DAST") unless has_dast_reports?

      compare_reports(::Ci::CompareDastReportsService, current_user)
    end

    def compare_license_scanning_reports(current_user)
      return missing_report_error("license scanning") unless has_license_scanning_reports?

      compare_reports(::Ci::CompareLicenseScanningReportsService, current_user)
    end

    def has_metrics_reports?
      !!(actual_head_pipeline&.has_reports?(::Ci::JobArtifact.metrics_reports))
    end

    def compare_metrics_reports
      return missing_report_error("metrics") unless has_metrics_reports?

      compare_reports(::Ci::CompareMetricsReportsService)
    end

    def synchronize_approval_rules_from_target_project
      return if merged?

      project_rules = target_project.approval_rules.report_approver.includes(:users, :groups)
      project_rules.find_each do |project_rule|
        project_rule.apply_report_approver_rules_to(self)
      end
    end

    private

    def missing_report_error(report_type)
      { status: :error, status_reason: "This merge request does not have #{report_type} reports" }
    end

    def report_type_enabled?(report_type)
      !!actual_head_pipeline&.batch_lookup_report_artifact_for_file_type(report_type)
    end
  end
end
