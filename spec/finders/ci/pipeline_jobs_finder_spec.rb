# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineJobsFinder, '#execute' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let_it_be(:job) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline) }

  let(:params) { { pipeline_id: pipeline.id } }

  subject { described_class.new(user, project, params).execute }

  context 'when user is not authorized' do
    it 'returns an AccessDenied error' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when user is authorized' do
    before do
      project.add_maintainer(user)
    end

    context 'when not given a type parameter' do
      it 'returns the builds for a pipeline' do
        expect(subject).to match_array([job])
      end
    end

    context 'when given bridges as a type parameter' do
      let(:params) { { pipeline_id: pipeline.id, type: :bridges } }

      it 'returns bridges' do
        expect(subject).to match_array([bridge])
      end
    end

    context 'when given a scope filter' do
      let(:params) { { pipeline_id: pipeline.id, scope: ['running'] } }
      let(:job_2) { create(:ci_build, :running, pipeline: pipeline) }

      it 'filters by the job statuses in the scope' do
        expect(subject).to match_array([job_2])
      end
    end
  end
end
