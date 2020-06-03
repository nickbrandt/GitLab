# frozen_string_literal: true

require 'spec_helper'

describe CreateEvidenceWithPipelineWorker do
  let(:project) { create(:project, :repository) }
  let(:release) { create(:release, project: project) }
  let(:pipeline) { create(:ci_empty_pipeline, sha: release.sha, project: project) }

  it 'creates a new Evidence record' do
    expect_next_instance_of(::Releases::CreateEvidenceService, release, pipeline: pipeline) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    expect { described_class.new.perform(release.id, pipeline.id) }.to change(Releases::Evidence, :count).by(1)
  end
end
