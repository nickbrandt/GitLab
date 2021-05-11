# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineRunnersMatchingValidationService do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let_it_be_with_reload(:pipeline) do
    create(:ci_pipeline, project: project, status: :created)
  end

  let_it_be_with_reload(:job) do
    create(:ci_build, project: project, pipeline: pipeline)
  end

  describe '#execute' do
    subject(:execute) { described_class.new(pipeline).execute }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(ci_drop_new_builds_when_ci_quota_exceeded: false)
      end

      it 'does not drop the jobs' do
        expect { execute }.not_to change { job.reload.status }
      end
    end

    context 'when the pipeline status is not created' do
      before do
        pipeline.update!(status: :running)
      end

      it 'does not drop the jobs' do
        expect { execute }.not_to change { job.reload.status }
      end
    end

    context 'when there are no runners available' do
      it 'drops the job' do
        execute
        job.reload

        expect(job).to be_failed
        expect(job.failure_reason).to eq('no_matching_runner')
      end
    end

    context 'with project runners' do
      let_it_be(:project_runner) do
        create(:ci_runner, runner_type: :project_type, projects: [project])
      end

      it 'does not drop the jobs' do
        expect { execute }.not_to change { job.reload.status }
      end
    end

    context 'with group runners' do
      let_it_be(:group_runner) do
        create(:ci_runner, runner_type: :group_type, groups: [group])
      end

      it 'does not drop the jobs' do
        expect { execute }.not_to change { job.reload.status }
      end
    end

    context 'with instance runners' do
      let_it_be(:instance_runner) do
        create(:ci_runner, runner_type: :instance_type)
      end

      it 'does not drop the jobs' do
        expect { execute }.not_to change { job.reload.status }
      end
    end
  end
end
