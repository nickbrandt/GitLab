# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreatePipelineService, '#execute' do
  set(:namespace) { create(:namespace) }
  set(:gold_plan) { create(:gold_plan) }
  set(:plan_limits) { create(:plan_limits, plan: gold_plan) }
  set(:project) { create(:project, :repository, namespace: namespace) }
  set(:user) { create(:user) }

  let(:service) do
    params = { ref: 'master',
               before: '00000000',
               after: project.commit.id,
               commits: [{ message: 'some commit' }] }

    described_class.new(project, user, params)
  end

  before do
    create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan)

    project.add_developer(user)
    stub_ci_pipeline_to_return_yaml_file
  end

  describe 'CI/CD Quotas / Limits' do
    context 'when there are not limits enabled' do
      it 'enqueues a new pipeline' do
        pipeline = create_pipeline!

        expect(pipeline).to be_persisted
        expect(pipeline).to be_pending
      end
    end

    context 'when pipeline activity limit is exceeded' do
      before do
        plan_limits.update_column(:ci_active_pipelines, 2)

        create(:ci_pipeline, project: project, status: 'pending')
        create(:ci_pipeline, project: project, status: 'running')
      end

      it 'drops the pipeline and does not process jobs' do
        pipeline = create_pipeline!

        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.statuses).not_to be_empty
        expect(pipeline.statuses).to all(be_created)
        expect(pipeline.activity_limit_exceeded?).to be true
      end
    end

    context 'when pipeline size limit is exceeded' do
      before do
        plan_limits.update_column(:ci_pipeline_size, 2)
      end

      it 'drops pipeline without creating jobs' do
        pipeline = create_pipeline!

        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.statuses).to be_empty
        expect(pipeline.size_limit_exceeded?).to be true
      end
    end
  end

  describe 'cross-project pipeline triggers' do
    before do
      stub_feature_flags(cross_project_pipeline_triggers: true)

      stub_ci_pipeline_yaml_file <<~YAML
        test:
          script: rspec

        deploy:
          variables:
            CROSS: downstream
          stage: deploy
          trigger: my/project
      YAML
    end

    it 'creates bridge jobs correctly' do
      pipeline = create_pipeline!

      test = pipeline.statuses.find_by(name: 'test')
      bridge = pipeline.statuses.find_by(name: 'deploy')

      expect(pipeline).to be_persisted
      expect(test).to be_a Ci::Build
      expect(bridge).to be_a Ci::Bridge
      expect(bridge.stage).to eq 'deploy'
      expect(pipeline.statuses).to match_array [test, bridge]
      expect(bridge.options).to eq('trigger' => { 'project' => 'my/project' })
      expect(bridge.yaml_variables)
        .to include(key: 'CROSS', value: 'downstream', public: true)
    end
  end

  def create_pipeline!
    service.execute(:push)
  end
end
