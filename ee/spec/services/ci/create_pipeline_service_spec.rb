# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreatePipelineService, '#execute' do
  set(:namespace) { create(:namespace) }
  set(:gold_plan) { create(:gold_plan) }
  set(:plan_limits) { create(:plan_limits, plan: gold_plan) }
  set(:project) { create(:project, :repository, namespace: namespace) }
  set(:user) { create(:user) }
  let(:ref_name) { 'master' }

  let(:service) do
    params = { ref: ref_name,
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

    context 'when configured with rules' do
      before do
        stub_ci_pipeline_yaml_file(config)
      end

      let(:downstream_project) { create(:project, :repository) }

      let(:config) do
        <<-EOY
          hello:
            script: echo world

          bridge-job:
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"
            trigger:
              project: #{downstream_project.full_path}
              branch: master
        EOY
      end

      context 'that include the bridge job' do
        it 'persists the bridge job' do
          pipeline = create_pipeline!

          expect(pipeline.processables.pluck(:name)).to contain_exactly('hello', 'bridge-job')
        end
      end

      context 'that exclude the bridge job' do
        let(:ref_name) { 'refs/heads/wip' }

        it 'does not include the bridge job' do
          pipeline = create_pipeline!

          expect(pipeline.processables.pluck(:name)).to eq(%w[hello])
        end
      end
    end
  end

  describe 'child pipeline triggers' do
    before do
      stub_ci_pipeline_yaml_file <<~YAML
        test:
          script: rspec

        deploy:
          variables:
            CROSS: downstream
          stage: deploy
          trigger:
            include:
              - local: path/to/child.yml
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
      expect(bridge.options).to eq(
        'trigger' => { 'include' => [{ 'local' => 'path/to/child.yml' }] }
      )
      expect(bridge.yaml_variables)
        .to include(key: 'CROSS', value: 'downstream', public: true)
    end
  end

  describe 'child pipeline triggers' do
    context 'when YAML is valid' do
      before do
        stub_ci_pipeline_yaml_file <<~YAML
          test:
            script: rspec

          deploy:
            variables:
              CROSS: downstream
            stage: deploy
            trigger:
              include:
                - local: path/to/child.yml
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
        expect(bridge.options).to eq(
          'trigger' => { 'include' => [{ 'local' => 'path/to/child.yml' }] }
        )
        expect(bridge.yaml_variables)
          .to include(key: 'CROSS', value: 'downstream', public: true)
      end
    end

    context 'when YAML is invalid' do
      let(:config) do
        {
          test: { script: 'rspec' },
          deploy: {
            trigger: { include: included_files }
          }
        }
      end

      let(:included_files) do
        Array.new(include_max_size + 1) do |index|
          { local: "file#{index}.yml" }
        end
      end

      let(:include_max_size) do
        EE::Gitlab::Ci::Config::Entry::Trigger::ComplexTrigger::SameProjectTrigger::INCLUDE_MAX_SIZE
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      it 'returns errors' do
        pipeline = create_pipeline!

        expect(pipeline.errors.full_messages.first).to match(/trigger:include config is too long/)
        expect(pipeline.failure_reason).to eq 'config_error'
        expect(pipeline).to be_persisted
        expect(pipeline.status).to eq 'failed'
      end
    end
  end

  def create_pipeline!
    service.execute(:push)
  end
end
