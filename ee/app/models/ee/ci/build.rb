# frozen_string_literal: true

module EE
  module Ci
    # Build EE mixin
    #
    # This module is intended to encapsulate EE-specific model logic
    # and be included in the `Build` model
    module Build
      extend ActiveSupport::Concern

      LICENSED_PARSER_FEATURES = {
        sast: :sast,
        dependency_scanning: :dependency_scanning,
        container_scanning: :container_scanning
      }.with_indifferent_access.freeze

      prepended do
        after_save :stick_build_if_status_changed

        has_many :sourced_pipelines,
          class_name: ::Ci::Sources::Pipeline,
          foreign_key: :source_job_id

        scope :with_security_reports, -> do
          with_existing_job_artifacts(::Ci::JobArtifact.security_reports)
            .eager_load_job_artifacts
        end

        scope :with_license_management_reports, -> do
          with_existing_job_artifacts(::Ci::JobArtifact.license_management_reports)
              .eager_load_job_artifacts
        end
      end

      def shared_runners_minutes_limit_enabled?
        runner && runner.instance_type? && project.shared_runners_minutes_limit_enabled?
      end

      def stick_build_if_status_changed
        return unless status_changed?
        return unless running?

        ::Gitlab::Database::LoadBalancing::Sticking.stick(:build, id)
      end

      def log_geo_deleted_event
        # It is not needed to generate a Geo deleted event
        # since Legacy Artifacts are migrated to multi-build artifacts
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/46652
      end

      def has_artifact?(name)
        options.dig(:artifacts, :paths)&.include?(name) &&
          artifacts_metadata?
      end

      def collect_security_reports!(security_reports)
        each_report(::Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES) do |file_type, blob|
          next if file_type == "dependency_scanning" &&
              ::Feature.disabled?(:parse_dependency_scanning_reports, default_enabled: true)

          next if file_type == "container_scanning" &&
              ::Feature.disabled?(:parse_container_scanning_reports, default_enabled: true)

          security_reports.get_report(file_type).tap do |security_report|
            begin
              next unless project.feature_available?(LICENSED_PARSER_FEATURES.fetch(file_type))

              ::Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, security_report)
            rescue => e
              security_report.error = e
            end
          end
        end
      end

      def collect_license_management_reports!(license_management_report)
        each_report(::Ci::JobArtifact::LICENSE_MANAGEMENT_REPORT_FILE_TYPES) do |file_type, blob|
          ::Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, license_management_report)
        end

        license_management_report
      end

      private

      def name_in?(names)
        name.in?(Array(names))
      end
    end
  end
end
