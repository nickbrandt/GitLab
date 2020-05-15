# frozen_string_literal: true

module EE
  module Evidences
    module ReleaseEntity
      extend ActiveSupport::Concern

      prepended do
        expose :test_report_artifacts, using: ::Evidences::BuildArtifactEntity,
               if: -> (release) { release.project.beta_feature_available?(:release_evidence_test_artifacts) }

        private

        def test_report_artifacts
          object.commit&.last_pipeline&.latest_report_builds || []
        end
      end
    end
  end
end
