# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineBridgeService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, :success, project: project) }

  describe '#execute' do
    subject { described_class.new(project, user).execute(pipeline) }

    context 'when pipeline has bridged jobs' do
      let(:bridge) { create(:ci_bridge, status: :pending) }

      before do
        pipeline.bridged_jobs << bridge
      end

      it 'updates the bridge status with the pipeline status' do
        expect { subject }.to change { bridge.status }.from('pending').to('success')
      end
    end
  end
end
