# frozen_string_literal: true

module EE
  module Releases
    module CreateEvidenceService
      def evidence_options
        options = super

        if release.project.beta_feature_available?(:release_evidence_test_artifacts)
          options[:report_artifacts] = report_artifacts
        end

        options
      end

      def report_artifacts
        pipeline&.latest_report_builds || []
      end
    end
  end
end
