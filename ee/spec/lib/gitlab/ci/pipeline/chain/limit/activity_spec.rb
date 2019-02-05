require 'spec_helper'

describe ::Gitlab::Ci::Pipeline::Chain::Limit::Activity do
  set(:namespace) { create(:namespace) }
  set(:project) { create(:project, namespace: namespace) }
  set(:user) { create(:user) }

  let(:command) do
    double('command', project: project, current_user: user)
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when active pipelines limit is exceeded' do
    before do
      gold_plan = create(:gold_plan, active_pipelines_limit: 1)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)

      create(:ci_pipeline, project: project, status: 'pending')
      create(:ci_pipeline, project: project, status: 'running')

      step.perform!
    end

    it 'drops the pipeline' do
      expect(pipeline.reload).to be_failed
    end

    it 'persists the pipeline' do
      expect(pipeline).to be_persisted
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'sets a valid failure reason' do
      expect(pipeline.activity_limit_exceeded?).to be true
    end
  end

  context 'when pipeline size limit is not exceeded' do
    before do
      step.perform!
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'does not invalidate the pipeline' do
      expect(pipeline.errors).to be_empty
    end
  end
end
