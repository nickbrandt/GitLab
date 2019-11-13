# frozen_string_literal: true

require 'spec_helper'

describe Ci::TriggerDownstreamSubscriptionService do
  describe '#execute' do
    subject(:execute) { described_class.new(pipeline.project, pipeline.user).execute(pipeline) }

    let(:upstream_project) { create(:project, :public) }
    let(:pipeline) { create(:ci_pipeline, project: upstream_project, user: create(:user)) }

    context 'when pipeline project has downstream projects' do
      before do
        create(:project, :repository, upstream_projects: [upstream_project])
      end

      it 'calls the create pipeline service' do
        service_double = instance_double(::Ci::CreatePipelineService)
        expect(service_double).to receive(:execute)
        expect(::Ci::CreatePipelineService).to receive(:new).with(
          an_instance_of(Project), an_instance_of(User), ref: 'master'
        ).and_return(service_double)

        execute
      end
    end

    context 'when pipeline project does not have downstream projects' do
      it 'does not call the create pipeline service' do
        expect(::Ci::CreatePipelineService).not_to receive(:new)

        execute
      end
    end
  end
end
