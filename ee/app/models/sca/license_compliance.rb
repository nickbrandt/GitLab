# frozen_string_literal: true

module SCA
  class LicenseCompliance
    include ::Gitlab::Utils::StrongMemoize

    def initialize(project)
      @project = project
    end

    def policies
      strong_memoize(:policies) do
        configured_policies = project.software_license_policies.index_by { |policy| policy.software_license.canonical_id }
        detected_licenses = license_scan_report.licenses.map do |reported_license|
          policy = configured_policies[reported_license.canonical_id]
          configured_policies.delete(reported_license.canonical_id) if policy
          build_policy(reported_license, policy)
        end
        undetected_licenses = configured_policies.map do |id, policy|
          build_policy(license_scan_report.fetch(id, nil), policy)
        end
        (detected_licenses + undetected_licenses).sort_by(&:name)
      end
    end

    def latest_build_for_default_branch
      return if pipeline.blank?

      strong_memoize(:latest_build_for_default_branch) do
        pipeline.builds.latest.license_scan.last
      end
    end

    private

    attr_reader :project

    def pipeline
      strong_memoize(:pipeline) do
        project.all_pipelines.latest_successful_for_ref(project.default_branch)
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
