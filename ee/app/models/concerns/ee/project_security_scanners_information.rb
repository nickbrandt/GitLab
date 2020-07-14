# frozen_string_literal: true

module EE
  module ProjectSecurityScannersInformation
    include ::Gitlab::Utils::StrongMemoize
    include LatestPipelineInformation

    SECURITY_SCANNERS_NAME_MAP = { sast: 'SAST',
                                   dast: 'DAST',
                                   dependency_scanning: 'DEPENDENCY_SCANNING',
                                   container_scanning: 'CONTAINER_SCANNING',
                                   secret_detection: 'SECRET_DETECTION' }.freeze

    def available_scanners
      SECURITY_SCANNERS_NAME_MAP.map { |key, value| value if feature_available?(key)}.compact
    end

    # For AutoDevOps, there is no guarantee that we will have builds for all scanners. That is why we need special handling for AutoDevOps
    def enabled_scanners
      return SECURITY_SCANNERS_NAME_MAP.values if auto_devops_source?

      latest_builds_reports.map {|scanner| SECURITY_SCANNERS_NAME_MAP[scanner]}.compact
    end

    def scanners_run_in_last_pipeline
      latest_builds_reports(only_successful_builds: true).map do |scanner|
        SECURITY_SCANNERS_NAME_MAP[scanner]
      end.compact
    end
  end
end
