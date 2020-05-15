# frozen_string_literal: true

require 'spec_helper'

describe Evidences::ReleaseEntity do
  let(:project) { create(:project, :repository) }
  let(:release) { build(:release, project: project) }
  let(:entity) { described_class.new(release) }

  subject { entity.as_json }

  it 'has not report_artifacts if feature is unlicenced' do
    stub_licensed_features(release_evidence_test_artifacts: false)

    expect(subject).not_to have_key(:report_artifacts)
  end

  context "when release_evidence_test_artifacts feature is licenced" do
    before do
      stub_licensed_features(release_evidence_test_artifacts: true)
    end

    it 'exposes empty artifacts array' do
      expect(subject[:report_artifacts]).to be_empty
    end

    context 'when there is pipeline with artifacts' do
      let(:pipeline) { create(:ci_empty_pipeline, sha: release.sha, project: project) }
      let!(:build_artifact) { create(:ci_build, :artifacts, pipeline: pipeline, name: 'build_1') }
      let!(:build_test_report) { create(:ci_build, :test_reports, pipeline: pipeline, name: 'build_2') }
      let!(:build_coverage_report) { create(:ci_build, :coverage_reports, pipeline: pipeline, name: 'build_3') }

      it 'exposes build artifacts' do
        expect(subject[:report_artifacts]).to(
          contain_exactly(
            Evidences::BuildArtifactEntity.new(build_test_report).as_json,
            Evidences::BuildArtifactEntity.new(build_coverage_report).as_json
          )
        )
      end
    end
  end
end
