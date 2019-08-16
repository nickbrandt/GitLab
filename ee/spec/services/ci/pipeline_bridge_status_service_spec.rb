# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineBridgeStatusService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, status: status, project: project) }

  describe '#execute' do
    subject { described_class.new(project, user).execute(pipeline) }

    context 'when pipeline has bridged jobs' do
      let(:bridge) { create(:ci_bridge, status: 'pending') }

      before do
        pipeline.downstream_bridges << bridge
      end

      context 'when pipeline has the same status as the bridge' do
        let(:status) { 'running' }

        before do
          bridge.status = 'running'
        end

        it 'does not update the bridge status' do
          expect { subject }.not_to change { bridge.status }
        end

        it 'does not save the bridge' do
          expect(bridge).not_to receive(:save!)
        end
      end

      context 'when pipeline starts running' do
        let(:status) { 'running' }

        it 'updates the bridge status with the pipeline status' do
          expect { subject }.to change { bridge.status }.from('pending').to('running')
        end

        it 'persists the status change' do
          expect(bridge).to be_persisted
        end
      end

      context 'when pipeline succeeds' do
        let(:status) { 'success' }

        it 'updates the bridge status with the pipeline status' do
          expect { subject }.to change { bridge.status }.from('pending').to('success')
        end

        it 'persists the status change' do
          expect(bridge).to be_persisted
        end
      end

      context 'when pipeline gets blocked' do
        let(:status) { 'manual' }

        it 'updates the bridge status with the pipeline status' do
          expect { subject }.to change { bridge.status }.from('pending').to('manual')
        end

        it 'persists the status change' do
          expect(bridge).to be_persisted
        end
      end
    end
  end
end
