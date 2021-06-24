# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::AddJobService do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  let(:job) { build(:ci_build) }

  subject(:service) { described_class.new(pipeline) }

  context 'when the pipeline is not persisted' do
    let(:pipeline) { build(:ci_pipeline) }

    it 'raises error' do
      expect { service }.to raise_error('Pipeline must be persisted for this service to be used')
    end
  end

  it 'assigns pipeline attributes to the job' do
    expect do
      service.execute!(job)
    end.to change { job.slice(:pipeline, :project, :ref) }.to(
      pipeline: pipeline, project: pipeline.project, ref: pipeline.ref
    )
  end

  it 'returns the job itself' do
    expect(service.execute!(job)).to eq(job)
  end

  it 'calls update_older_statuses_retried!' do
    expect(job).to receive(:update_older_statuses_retried!)

    service.execute!(job)
  end

  context 'when the FF ci_fix_commit_status_retried is disabled' do
    before do
      stub_feature_flags(ci_fix_commit_status_retried: false)
    end

    it 'does not call update_older_statuses_retried!' do
      expect(job).not_to receive(:update_older_statuses_retried!)

      service.execute!(job)
    end
  end
end
