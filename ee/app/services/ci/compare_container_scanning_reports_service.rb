# frozen_string_literal: true

module Ci
  class CompareContainerScanningReportsService < ::Ci::CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer
    end

    def serializer_class
      Vulnerabilities::OccurrenceDiffSerializer
    end

    def get_report(pipeline)
      Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: { report_type: %w[container_scanning], scope: 'all' }).execute
    end
  end
end
