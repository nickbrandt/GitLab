# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Ci::Pipeline::Quota::JobActivity do
  let_it_be(:namespace, refind: true) { create(:namespace) }
  let_it_be(:project, refind: true) { create(:project, namespace: namespace) }
  let(:gold_plan) { create(:gold_plan, active_jobs_limit: active_jobs_limit) }

  let(:limit) { described_class.new(namespace, project) }

  before do
    create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      let(:active_jobs_limit) { 10 }

      it 'is enabled' do
        expect(limit).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      let(:active_jobs_limit) { 0 }

      it 'is not enabled' do
        expect(limit).not_to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    let(:active_jobs_limit) { 2 }

    context 'when pipelines created recently' do
      context 'and pipelines are running' do
        let(:pipeline1) { create(:ci_pipeline, project: project, status: 'created', created_at: Time.now) }
        let(:pipeline2) { create(:ci_pipeline, project: project, status: 'created', created_at: Time.now) }

        before do
          create(:ci_build, pipeline: pipeline1)
          create(:ci_build, pipeline: pipeline2)
        end

        context 'when count of jobs in alive pipelines is below the limit' do
          it 'is not exceeded' do
            expect(limit).not_to be_exceeded
          end
        end

        context 'when count of jobs in alive pipelines is above the limit' do
          before do
            create(:ci_build, pipeline: pipeline2)
          end

          it 'is exceeded' do
            expect(limit).to be_exceeded
          end
        end
      end

      context 'and pipelines are completed' do
        before do
          create(:ci_pipeline, project: project, status: 'success', created_at: Time.now).tap do |pipeline|
            create(:ci_build, pipeline: pipeline)
            create(:ci_build, pipeline: pipeline)
            create(:ci_build, pipeline: pipeline)
          end
        end

        it 'is not exceeded' do
          expect(limit).not_to be_exceeded
        end
      end
    end

    context 'when pipelines are older than 24 hours' do
      before do
        create(:ci_pipeline, project: project, status: 'created', created_at: 25.hours.ago).tap do |pipeline|
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
        end
      end

      it 'is not exceeded' do
        expect(limit).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      let(:active_jobs_limit) { 1 }

      before do
        create(:ci_pipeline, project: project, status: 'created', created_at: Time.now).tap do |pipeline|
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
          create(:ci_build, pipeline: pipeline)
        end
      end

      it 'returns info about pipeline activity limit exceeded' do
        expect(limit.message)
          .to eq "Active jobs limit exceeded by 2 jobs in the past 24 hours!"
      end
    end
  end
end
