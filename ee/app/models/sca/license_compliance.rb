# frozen_string_literal: true

module SCA
  class LicenseCompliance
    include ::Gitlab::Utils::StrongMemoize

    def initialize(project)
      @project = project
    end

    def policies
      strong_memoize(:policies) do
        new_policies.merge(known_policies).sort.map(&:last)
      end
    end

    def latest_build_for_default_branch
      return if pipeline.blank?

      strong_memoize(:latest_build_for_default_branch) do
        pipeline.builds.latest.license_scan.last
      end
    end

    def report_for(policy)
      build_policy(license_scan_report[policy.software_license.canonical_id], policy)
    end

    private

    attr_reader :project

    def known_policies
      strong_memoize(:known_policies) do
        project.software_license_policies.including_license.unreachable_limit.map do |policy|
          [policy.software_license.canonical_id, report_for(policy)]
        end.to_h
      end
    end

    def new_policies
      license_scan_report.licenses.map do |reported_license|
        next if known_policies[reported_license.canonical_id]

        [reported_license.canonical_id, build_policy(reported_license, nil)]
      end.compact.to_h
    end

    def pipeline
      strong_memoize(:pipeline) do
        project.latest_pipeline_with_reports(::Ci::JobArtifact.license_management_reports)
      end
    end

    def license_scan_report
      return empty_report if pipeline.blank?

      strong_memoize(:license_scan_report) do
        pipeline.license_scanning_report.tap do |report|
          report.apply_details_from!(dependency_list_report)
        end
      rescue ::Gitlab::Ci::Parsers::LicenseCompliance::LicenseScanning::LicenseScanningParserError
        empty_report
      end
    end

    def dependency_list_report
      pipeline.dependency_list_report
    rescue ::Gitlab::Ci::Parsers::LicenseCompliance::LicenseScanning::LicenseScanningParserError
    end

    def empty_report
      ::Gitlab::Ci::Reports::LicenseScanning::Report.new
    end

    def build_policy(reported_license, software_license_policy)
      ::SCA::LicensePolicy.new(reported_license, software_license_policy)
    end
  end
end
