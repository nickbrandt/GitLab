# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildArtifactEntity do
  let(:job) { create(:ci_build) }
  let(:artifact) { create(:ci_job_artifact, :codequality, expire_at: 1.hour.from_now, job: job) }
  let(:presenter) { Ci::BuildArtifactPresenter.new(artifact, display_index: 1) }

  let(:entity) do
    described_class.new(presenter, request: double)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'name contains job name and file type name' do
      expect(subject[:name]).to eq "test:codequality"
    end

    it 'exposes information about expiration of artifacts' do
      expect(subject).to include(:expired, :expire_at)
    end

    it 'contains paths to the artifacts' do
      expect(subject[:path])
        .to include "jobs/#{job.id}/artifacts/download?artifact_id=#{artifact.id}"

      expect(subject[:keep_path])
        .to include "jobs/#{job.id}/artifacts/keep"

      expect(subject[:browse_path])
        .to include "jobs/#{job.id}/artifacts/browse"
    end

    context 'when archive' do
      let(:artifact) { create(:ci_job_artifact) }

      it 'serializes the name' do
        expect(subject[:name]).to eq "test:artifact1:archive"
      end
    end
  end
end
