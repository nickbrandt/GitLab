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
      include IterationEventable

      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_users, through: :approvers, source: :user
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :status_check_responses, class_name: 'MergeRequests::StatusCheckResponse', inverse_of: :merge_request
      has_many :approval_rules, class_name: 'ApprovalMergeRequestRule', inverse_of: :merge_request do
        def applicable_to_branch(branch)
          ActiveRecord::Associations::Preloader.new.preload(
            self,
            [:users, :groups, approval_project_rule: [:users, :groups, :protected_branches]]
          )

          self.select do |rule|
            next true unless rule.approval_project_rule.present?
            next true if rule.overridden?

            rule.approval_project_rule.applies_to_branch?(branch)
          end
        end
      end
      has_many :approval_merge_request_rule_sources, through: :approval_rules
      has_many :approval_project_rules, through: :approval_merge_request_rule_sources
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

      scope :including_merge_train, -> do
        includes(:merge_train)
      end

      def merge_requests_author_approval?
        !!target_project&.merge_requests_author_approval?
      end

      def merge_requests_disable_committers_approval?
        !!target_project&.merge_requests_disable_committers_approval?
      end
    end

    class_methods do
      # This is an ActiveRecord scope in CE
      def with_api_entity_associations
        super.preload(:blocking_merge_requests, target_project: [group: :saml_provider])
      end

      def sort_by_attribute(method, *args, **kwargs)
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

      # override
      def use_separate_indices?
        Elastic::DataMigrationService.migration_has_finished?(:migrate_merge_requests_to_separate_index)
      end
    end

    override :predefined_variables
    def predefined_variables
      super.concat(merge_request_approval_variables)
    end

    override :mergeable?
    def mergeable?(skip_ci_check: false, skip_discussions_check: false)
      return false unless approved?
      return false if has_denied_policies?
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

    def allows_multiple_reviewers?
      project.feature_available?(:multiple_merge_request_reviewers)
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

    def has_denied_policies?
      return false unless project.feature_available?(:license_scanning)

      return false unless has_license_scanning_reports?

      return false if has_approved_license_check?

      report_diff = compare_reports(::Ci::CompareLicenseScanningReportsService)

      licenses = report_diff.dig(:data, 'new_licenses')

      return false if licenses.nil? || licenses.empty?

      licenses.any? do |l|
        status = l.dig('classification', 'approval_status')
        %w(blacklisted denied).include?(status)
      end
    end

    def enabled_reports
      {
        sast: report_type_enabled?(:sast),
        container_scanning: report_type_enabled?(:container_scanning),
        dast: report_type_enabled?(:dast),
        dependency_scanning: report_type_enabled?(:dependency_scanning),
        license_scanning: report_type_enabled?(:license_scanning),
        coverage_fuzzing: report_type_enabled?(:coverage_fuzzing),
        secret_detection: report_type_enabled?(:secret_detection),
        api_fuzzing: report_type_enabled?(:api_fuzzing)
      }
    end

    def has_security_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.security_reports)
    end

    def has_dependency_scanning_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.dependency_list_reports)
    end

    def compare_dependency_scanning_reports(current_user)
      return missing_report_error("dependency scanning") unless has_dependency_scanning_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'dependency_scanning')
    end

    def has_license_scanning_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.license_scanning_reports)
    end

    def has_container_scanning_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.container_scanning_reports)
    end

    def compare_container_scanning_reports(current_user)
      return missing_report_error("container scanning") unless has_container_scanning_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'container_scanning')
    end

    def has_dast_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.dast_reports)
    end

    def compare_dast_reports(current_user)
      return missing_report_error("DAST") unless has_dast_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'dast')
    end

    def compare_license_scanning_reports(current_user)
      return missing_report_error("license scanning") unless actual_head_pipeline&.license_scan_completed?

      compare_reports(::Ci::CompareLicenseScanningReportsService, current_user)
    end

    def has_metrics_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.metrics_reports)
    end

    def compare_metrics_reports
      return missing_report_error("metrics") unless has_metrics_reports?

      compare_reports(::Ci::CompareMetricsReportsService)
    end

    def has_coverage_fuzzing_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.coverage_fuzzing_reports)
    end

    def compare_coverage_fuzzing_reports(current_user)
      return missing_report_error("coverage fuzzing") unless has_coverage_fuzzing_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'coverage_fuzzing')
    end

    def has_api_fuzzing_reports?
      !!actual_head_pipeline&.has_reports?(::Ci::JobArtifact.api_fuzzing_reports)
    end

    def compare_api_fuzzing_reports(current_user)
      return missing_report_error('api fuzzing') unless has_api_fuzzing_reports?

      compare_reports(::Ci::CompareSecurityReportsService, current_user, 'api_fuzzing')
    end

    def synchronize_approval_rules_from_target_project
      return if merged?

      project_rules = target_project.approval_rules.report_approver.includes(:users, :groups)
      project_rules.find_each do |project_rule|
        project_rule.apply_report_approver_rules_to(self)
      end
    end

    def missing_security_scan_types
      return [] unless actual_head_pipeline && base_pipeline

      (base_pipeline.security_scans.pluck(:scan_type) - actual_head_pipeline.security_scans.pluck(:scan_type)).uniq
    end

    def applicable_approval_rules_for_user(user_id)
      wrapped_approval_rules.select do |rule|
        rule.approvers.pluck(:id).include?(user_id)
      end
    end

    def security_reports_up_to_date?
      project.security_reports_up_to_date_for_ref?(target_branch)
    end

    private

    def has_approved_license_check?
      if rule = approval_rules.license_compliance.last
        ApprovalWrappedRule.wrap(self, rule).approved?
      end
    end

    def merge_request_approval_variables
      return unless approval_feature_available?

      strong_memoize(:merge_request_approval_variables) do
        ::Gitlab::Ci::Variables::Collection.new.tap do |variables|
          variables.append(key: 'CI_MERGE_REQUEST_APPROVED', value: approved?.to_s) if approved?
        end
      end
    end
  end
end
