# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineBridgeStatusService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, status, project: project) }

  describe '#execute' do
    subject { described_class.new(project, user).execute(pipeline) }

    context 'when pipeline has bridged jobs' do
      let(:bridge) { create(:ci_bridge, status: :pending) }

      before do
        pipeline.downstream_bridges << bridge
      end

      context 'when pipeline starts running' do
        let(:status) { :running }

        it 'updates the bridge status with the pipeline status' do
          expect { subject }.to change { bridge.status }.from('pending').to('running')
        end
      end

      context 'when pipeline succeeds' do
        let(:status) { :success }

        it 'updates the bridge status with the pipeline status' do
          expect { subject }.to change { bridge.status }.from('pending').to('success')
        end
      end

      context 'when pipeline gets blocked' do
        let(:status) { :blocked }

        it 'updates the bridge status with the pipeline status' do
          expect { subject }.to change { bridge.status }.from('pending').to('manual')
        end
      end
    end
  end
end
