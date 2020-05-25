# frozen_string_literal: true

require 'spec_helper'

describe Evidences::EvidenceEntity do
  let_it_be(:project) { create(:project, :repository) }
  let(:release) { create(:release, project: project) }
  let(:evidence) { build(:evidence, release: release) }
  let(:entity) { described_class.new(evidence) }
  let(:schema_file) { 'evidences/evidence' }

  describe '#generate_summary_and_sha' do
    context 'when evidence has report artifacts' do
      it 'creates a valid JSON object' do
        stub_licensed_features(release_evidence_test_artifacts: true)

        pipeline = create(:ci_empty_pipeline, sha: release.sha, project: project)
        create(:ci_build, :test_reports, pipeline: pipeline, name: 'build_1')
        summary_json = entity.to_json

        expect(summary_json['report_artifacts']).not_to be_empty
        expect(summary_json).to match_schema(schema_file)
      end
    end
  end
end
