module EE
  module Ci
    module Pipeline
      extend ActiveSupport::Concern

      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 20,
        size_limit_exceeded: 21
      }.freeze

      prepended do
        has_one :chat_data, class_name: 'Ci::PipelineChatData'

        has_many :job_artifacts, through: :builds

        scope :with_security_reports, -> {
          joins(:artifacts).where(ci_builds: { name: %w[sast dependency_scanning sast:container container_scanning dast] })
        }

        # This structure describes feature levels
        # to access the file types for given reports
        LEGACY_REPORT_LICENSED_FEATURES = {
          codequality: nil,
          sast: :sast,
          dependency_scanning: :dependency_scanning,
          container_scanning: :sast_container,
          dast: :dast
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
          }
        }.freeze
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

      def performance_artifact
        @performance_artifact ||= artifacts_with_files.find(&:has_performance_json?)
      end

      def license_management_artifact
        @license_management_artifact ||= artifacts_with_files.find(&:has_license_management_json?)
      end

      def has_license_management_data?
        license_management_artifact&.success?
      end

      def has_performance_data?
        performance_artifact&.success?
      end

      def expose_license_management_data?
        project.feature_available?(:license_management) &&
          has_license_management_data?
      end

      def expose_performance_data?
        project.feature_available?(:merge_request_performance_metrics) &&
          has_performance_data?
      end

      private

      def available_licensed_report_type?(file_type)
        feature_name = LEGACY_REPORT_LICENSED_FEATURES.fetch(file_type)
        feature_name.nil? || project.feature_available?(feature_name)
      end

      def artifacts_with_files
        @artifacts_with_files ||= artifacts.includes(:job_artifacts_metadata, :job_artifacts_archive).to_a
      end
    end
  end
end
