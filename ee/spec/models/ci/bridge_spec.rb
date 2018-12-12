require 'spec_helper'

describe Ci::Bridge do
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) do
    create(:ci_bridge, status: :created, pipeline: pipeline)
  end

  it 'has many sourced pipelines' do
    expect(bridge).to have_many(:sourced_pipelines)
  end

  describe 'state machine transitions' do
    context 'when it changes status from created to pending' do
      it 'schedules downstream pipeline creation' do
        expect(bridge).to receive(:schedule_downstream_pipeline!)

        bridge.enqueue!
      end
    end
  end
end
