# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteProjectJobArtifactsWorker do
  subject { described_class.new.perform(project.id) }

  let(:project) { create(:project) }
  let(:pipeline_1) { create(:ci_pipeline, project: project) }
  let(:pipeline_2) { create(:ci_pipeline, project: project) }

  before do
    build_1 = create(:ci_build, pipeline: pipeline_1)
    create(:ci_job_artifact, :trace, job: build_1)
    create(:ci_job_artifact, :metadata, job: build_1)
    create(:ci_job_artifact, :dotenv, job: build_1)

    build_2 = create(:ci_build, pipeline: pipeline_2)
    create(:ci_job_artifact, :metadata, job: build_2)
  end

  include_examples 'an idempotent worker' do
    subject { perform_multiple([project.id], exec_times: 2) }

    it 'removes erasable job artifacts of the given project' do
      expect { subject }.to change(::Ci::JobArtifact, :count).from(4).to(1)
    end
  end

  it 'removes erasable job artifacts of the given project' do
    expect { subject }.to change(::Ci::JobArtifact, :count).from(4).to(1)
  end
end
