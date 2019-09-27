# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Pipeline::Chain::Limit::JobActivity do
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

  context 'when active jobs limit is exceeded' do
    before do
      gold_plan = create(:gold_plan, active_jobs_limit: 2)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)

      pipeline = create(:ci_pipeline, project: project, status: 'running', created_at: Time.now)
      create(:ci_build, pipeline: pipeline)
      create(:ci_build, pipeline: pipeline)
      create(:ci_build, pipeline: pipeline)

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
      expect(pipeline.job_activity_limit_exceeded?).to be true
    end
  end

  context 'when job activity limit is not exceeded' do
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
