# frozen_string_literal: true

module EE
  module Ci
    module Pipeline
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 20,
        size_limit_exceeded: 21
      }.freeze

      prepended do
        include UsageStatistics

        has_many :vulnerabilities_occurrence_pipelines, class_name: 'Vulnerabilities::OccurrencePipeline'
        has_many :vulnerability_findings, source: :occurrence, through: :vulnerabilities_occurrence_pipelines, class_name: 'Vulnerabilities::Occurrence'

        has_many :auto_canceled_pipelines, class_name: 'Ci::Pipeline', foreign_key: 'auto_canceled_by_id'
        has_many :auto_canceled_jobs, class_name: 'CommitStatus', foreign_key: 'auto_canceled_by_id'

        # Subscriptions to this pipeline
        has_many :downstream_bridges, class_name: '::Ci::Bridge', foreign_key: :upstream_pipeline_id
        has_many :security_scans, class_name: 'Security::Scan', through: :builds

        has_one :source_project, class_name: 'Ci::Sources::Project', foreign_key: :pipeline_id

        # Legacy way to fetch security reports based on job name. This has been replaced by the reports feature.
        scope :with_legacy_security_reports, -> do
          joins(:downloadable_artifacts).where(ci_builds: { name: %w[sast secret_detection dependency_scanning sast:container container_scanning dast] })
        end

        scope :with_vulnerabilities, -> do
          where('EXISTS (?)', ::Vulnerabilities::OccurrencePipeline.where('ci_pipelines.id=vulnerability_occurrence_pipelines.pipeline_id').select(1))
        end

        # This structure describes feature levels
        # to access the file types for given reports
        REPORT_LICENSED_FEATURES = {
          codequality: nil,
          sast: %i[sast],
          secret_detection: %i[secret_detection],
          dependency_scanning: %i[dependency_scanning],
          container_scanning: %i[container_scanning],
          dast: %i[dast],
          performance: %i[merge_request_performance_metrics],
          license_management: %i[license_scanning],
          license_scanning: %i[license_scanning],
          metrics: %i[metrics_reports],
          requirements: %i[requirements]
        }.freeze

        state_machine :status do
          after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
            next unless pipeline.has_reports?(::Ci::JobArtifact.security_reports.or(::Ci::JobArtifact.license_scanning_reports))

            pipeline.run_after_commit do
              StoreSecurityReportsWorker.perform_async(pipeline.id) if pipeline.default_branch?
              SyncSecurityReportsToReportApprovalRulesWorker.perform_async(pipeline.id)
            end
          end

          after_transition any => ::Ci::Pipeline.bridgeable_statuses.map(&:to_sym) do |pipeline|
            next unless pipeline.downstream_bridges.any?

            pipeline.run_after_commit do
              ::Ci::PipelineBridgeStatusWorker.perform_async(pipeline.id)
            end
          end

          after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
            next unless pipeline.triggers_subscriptions?

            pipeline.run_after_commit do
              ::Ci::TriggerDownstreamSubscriptionsWorker.perform_async(pipeline.id)
            end
          end
        end
      end

      def triggers_subscriptions?
        # Currently we trigger subscriptions only for tags.
        tag? && project_has_subscriptions?
      end

      def retryable?
        !merge_train_pipeline? && super
      end

      def batch_lookup_report_artifact_for_file_type(file_type)
        return unless available_licensed_report_type?(file_type)

        latest_report_artifacts
          .values_at(*::Ci::JobArtifact.associated_file_types_for(file_type.to_s))
          .flatten
          .compact
          .last
      end

      def expose_license_scanning_data?
        batch_lookup_report_artifact_for_file_type(:license_scanning).present?
      end

      def security_reports
        ::Gitlab::Ci::Reports::Security::Reports.new(sha).tap do |security_reports|
          builds.latest.with_reports(::Ci::JobArtifact.security_reports).each do |build|
            build.collect_security_reports!(security_reports)
          end
        end
      end

      def license_scanning_report
        ::Gitlab::Ci::Reports::LicenseScanning::Report.new.tap do |license_management_report|
          builds.latest.with_reports(::Ci::JobArtifact.license_scanning_reports).each do |build|
            build.collect_license_scanning_reports!(license_management_report)
          end
        end
      end

      def dependency_list_report
        ::Gitlab::Ci::Reports::DependencyList::Report.new.tap do |dependency_list_report|
          builds.latest.with_reports(::Ci::JobArtifact.dependency_list_reports).each do |build|
            build.collect_dependency_list_reports!(dependency_list_report)
          end
          builds.latest.with_reports(::Ci::JobArtifact.license_scanning_reports).each do |build|
            build.collect_licenses_for_dependency_list!(dependency_list_report)
          end
        end
      end

      def metrics_report
        ::Gitlab::Ci::Reports::Metrics::Report.new.tap do |metrics_report|
          builds.latest.with_reports(::Ci::JobArtifact.metrics_reports).each do |build|
            build.collect_metrics_reports!(metrics_report)
          end
        end
      end

      ##
      # Check if it's a merge request pipeline with the HEAD of source and target branches
      # TODO: Make `Ci::Pipeline#latest?` compatible with merge request pipelines and remove this method.
      def latest_merge_request_pipeline?
        merge_request_pipeline? &&
          source_sha == merge_request.diff_head_sha &&
          target_sha == merge_request.target_branch_sha
      end

      override :merge_request_event_type
      def merge_request_event_type
        return unless merge_request?

        strong_memoize(:merge_request_event_type) do
          merge_train_pipeline? ? :merge_train : super
        end
      end

      def merge_train_pipeline?
        merge_request_pipeline? && merge_train_ref?
      end

      private

      def project_has_subscriptions?
        return false unless ::Feature.enabled?(:ci_project_subscriptions, project)

        project.downstream_projects.any?
      end

      def merge_train_ref?
        ::MergeRequest.merge_train_ref?(ref)
      end

      # This batch loads the latest reports for each CI job artifact
      # type (e.g. sast, dast, etc.) in a single SQL query to eliminate
      # the need to do N different `job_artifacts.where(file_type:
      # X).last` calls.
      #
      # Return a hash of file type => array of 1 job artifact
      def latest_report_artifacts
        ::Gitlab::SafeRequestStore.fetch("pipeline:#{self.id}:latest_report_artifacts") do
          # Note we use read_attribute(:project_id) to read the project
          # ID instead of self.project_id. The latter appears to load
          # the Project model. This extra filter doesn't appear to
          # affect query plan but included to ensure we don't leak the
          # wrong informaiton.
          ::Ci::JobArtifact.where(
            id: job_artifacts.with_reports
              .select('max(ci_job_artifacts.id) as id')
              .where(project_id: self.read_attribute(:project_id))
              .group(:file_type)
          )
            .preload(:job)
            .group_by(&:file_type)
        end
      end

      def available_licensed_report_type?(file_type)
        feature_names = REPORT_LICENSED_FEATURES.fetch(file_type)
        feature_names.nil? || feature_names.any? { |feature| project.feature_available?(feature) }
      end
    end
  end
end
