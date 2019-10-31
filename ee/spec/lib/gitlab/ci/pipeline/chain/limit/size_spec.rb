# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Pipeline::Chain::Limit::Size do
  set(:namespace) { create(:namespace) }
  set(:project) { create(:project, :repository, namespace: namespace) }
  set(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_pipeline_with_one_job, project: project,
                                     ref: 'master')
  end

  let(:command) do
    double('command', project: project,
                      current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  subject { step.perform! }

  context 'when pipeline size limit is exceeded' do
    before do
      gold_plan = create(:gold_plan, pipeline_size_limit: 1)
      create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)
    end

    let(:pipeline) do
      config = { rspec: { script: 'rspec' },
                 spinach: { script: 'spinach' } }

      create(:ci_pipeline, project: project, config: config)
    end

    context 'when saving incomplete pipelines' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: true)
      end

      it 'drops the pipeline' do
        subject

        expect(pipeline.reload).to be_failed
      end

      it 'persists the pipeline' do
        subject

        expect(pipeline).to be_persisted
      end

      it 'breaks the chain' do
        subject

        expect(step.break?).to be true
      end

      it 'sets a valid failure reason' do
        subject

        expect(pipeline.size_limit_exceeded?).to be true
      end

      it 'appends validation error' do
        subject

        expect(pipeline.errors.to_a)
          .to include 'Pipeline size limit exceeded by 1 job!'
      end

      it 'logs the error' do
        expect(Gitlab::Sentry).to receive(:track_acceptable_exception).with(
          instance_of(EE::Gitlab::Ci::Limit::LimitExceededError),
          extra: { project_id: project.id, plan: namespace.actual_plan_name }
        )

        subject
      end
    end

    context 'when not saving incomplete pipelines' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: false)
      end

      it 'does not drop the pipeline' do
        subject

        expect(pipeline).not_to be_failed
      end

      it 'breaks the chain' do
        subject

        expect(step.break?).to be true
      end
    end
  end

  context 'when pipeline size limit is not exceeded' do
    it 'does not break the chain' do
      subject

      expect(step.break?).to be false
    end

    it 'does not persist the pipeline' do
      subject

      expect(pipeline).not_to be_persisted
    end

    it 'does not log any error' do
      expect(Gitlab::Sentry).not_to receive(:track_acceptable_exception)

      subject
    end
  end
end
