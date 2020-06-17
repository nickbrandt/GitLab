# frozen_string_literal: true

module EE
  module Releases
    module CreateEvidenceService
      extend ::Gitlab::Utils::Override

      override :evidence_options
      def evidence_options
        options = super.dup

        if release.project.feature_available?(:release_evidence_test_artifacts)
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
