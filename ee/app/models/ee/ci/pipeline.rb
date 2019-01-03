# frozen_string_literal: true

module EE
  module Ci
    module Pipeline
      extend ActiveSupport::Concern

      BridgeStatusError = Class.new(StandardError)

      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 20,
        size_limit_exceeded: 21
      }.freeze

      prepended do
        has_one :chat_data, class_name: 'Ci::PipelineChatData'

        has_many :job_artifacts, through: :builds
        has_many :vulnerabilities_occurrence_pipelines, class_name: 'Vulnerabilities::OccurrencePipeline'
        has_many :vulnerabilities, source: :occurrence, through: :vulnerabilities_occurrence_pipelines, class_name: 'Vulnerabilities::Occurrence'

        has_one :source_pipeline, class_name: ::Ci::Sources::Pipeline, inverse_of: :pipeline
        has_many :sourced_pipelines, class_name: ::Ci::Sources::Pipeline, foreign_key: :source_pipeline_id

        has_one :triggered_by_pipeline, through: :source_pipeline, source: :source_pipeline
        has_one :source_job, through: :source_pipeline, source: :source_job
        has_one :source_bridge, through: :source_pipeline, source: :source_bridge
        has_many :triggered_pipelines, through: :sourced_pipelines, source: :pipeline

        has_many :auto_canceled_pipelines, class_name: 'Ci::Pipeline', foreign_key: 'auto_canceled_by_id'
        has_many :auto_canceled_jobs, class_name: 'CommitStatus', foreign_key: 'auto_canceled_by_id'

        # Legacy way to fetch security reports based on job name. This has been replaced by the reports feature.
        scope :with_legacy_security_reports, -> do
          joins(:artifacts).where(ci_builds: { name: %w[sast dependency_scanning sast:container container_scanning dast] })
        end

        # The new `reports:` syntax reports
        scope :with_security_reports, -> do
          where('EXISTS (?)', ::Ci::Build.latest.with_security_reports.where('ci_pipelines.id=ci_builds.commit_id').select(1))
        end

        scope :with_vulnerabilities, -> do
          where('EXISTS (?)', ::Vulnerabilities::OccurrencePipeline.where('ci_pipelines.id=vulnerability_occurrence_pipelines.pipeline_id').select(1))
        end

        # This structure describes feature levels
        # to access the file types for given reports
        REPORT_LICENSED_FEATURES = {
          codequality: nil,
          sast: %i[sast],
          dependency_scanning: %i[dependency_scanning],
          container_scanning: %i[container_scanning sast_container],
          dast: %i[dast],
          performance: %i[merge_request_performance_metrics],
          license_management: %i[license_management]
        }.freeze

        # Deprecated, to be removed in 12.0
        # A hash of Ci::JobArtifact file_types
        # With mapping to the legacy job names,
        # that has to contain given files
        LEGACY_REPORT_FORMATS = {
          codequality: {
            names: %w(codeclimate codequality code_quality),
            files: %w(codeclimate.json gl-code-quality-report.json)
          },
          sast: {
            names: %w(deploy sast),
            files: %w(gl-sast-report.json)
          },
          dependency_scanning: {
            names: %w(dependency_scanning),
            files: %w(gl-dependency-scanning-report.json)
          },
          container_scanning: {
            names: %w(sast:container container_scanning),
            files: %w(gl-sast-container-report.json gl-container-scanning-report.json)
          },
          dast: {
            names: %w(dast),
            files: %w(gl-dast-report.json)
          },
          performance: {
            names: %w(performance deploy),
            files: %w(performance.json)
          },
          license_management: {
            names: %w(license_management),
            files: %w(gl-license-management-report.json)
          }
        }.freeze

        state_machine :status do
          after_transition any => ::Ci::Pipeline::COMPLETED_STATUSES.map(&:to_sym) do |pipeline|
            next unless pipeline.has_security_reports? && pipeline.default_branch?

            pipeline.run_after_commit do
              StoreSecurityReportsWorker.perform_async(pipeline.id)
            end
          end

          after_transition created: :pending do |pipeline|
            next unless pipeline.bridge_triggered?

            pipeline.update_bridge_status!
          end
        end
      end

      def bridge_triggered?
        source_bridge.present?
      end

      def update_bridge_status!
        raise ArgumentError unless bridge_triggered?
        raise BridgeStatusError unless source_bridge.active?

        source_bridge.success!
      end

      def any_report_artifact_for_type(file_type)
        report_artifact_for_file_type(file_type) || legacy_report_artifact_for_file_type(file_type)
      end

      def report_artifact_for_file_type(file_type)
        return unless available_licensed_report_type?(file_type)

        job_artifacts.where(file_type: ::Ci::JobArtifact.file_types[file_type]).last
      end

      def legacy_report_artifact_for_file_type(file_type)
        return unless available_licensed_report_type?(file_type)

        legacy_names = LEGACY_REPORT_FORMATS[file_type]
        return unless legacy_names

        builds.success.latest.where(name: legacy_names[:names]).each do |build|
          legacy_names[:files].each do |file_name|
            next unless build.has_artifact?(file_name)

            return OpenStruct.new(build: build, path: file_name)
          end
        end

        # In case there is no artifact return nil
        nil
      end

      def expose_license_management_data?
        any_report_artifact_for_type(:license_management)
      end

      def has_security_reports?
        complete? && builds.latest.with_security_reports.any?
      end

      def security_reports
        ::Gitlab::Ci::Reports::Security::Reports.new.tap do |security_reports|
          builds.latest.with_security_reports.each do |build|
            build.collect_security_reports!(security_reports)
          end
        end
      end

      def has_license_management_reports?
        complete? && builds.latest.with_license_management_reports.any?
      end

      def license_management_report
        ::Gitlab::Ci::Reports::LicenseManagement::Report.new.tap do |license_management_report|
          builds.latest.with_license_management_reports.each do |build|
            build.collect_license_management_reports!(license_management_report)
          end
        end
      end

      private

      def available_licensed_report_type?(file_type)
        feature_names = REPORT_LICENSED_FEATURES.fetch(file_type)
        feature_names.nil? || feature_names.any? { |feature| project.feature_available?(feature) }
      end

      def artifacts_with_files
        @artifacts_with_files ||= artifacts.includes(:job_artifacts_metadata, :job_artifacts_archive).to_a
      end
    end
  end
end
