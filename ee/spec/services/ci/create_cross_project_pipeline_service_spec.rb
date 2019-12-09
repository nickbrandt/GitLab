# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreateCrossProjectPipelineService, '#execute' do
  set(:user) { create(:user) }
  set(:upstream_project) { create(:project, :repository) }
  set(:downstream_project) { create(:project, :repository) }

  set(:upstream_pipeline) do
    create(:ci_pipeline, :running, project: upstream_project)
  end

  let(:trigger) do
    {
      trigger: {
        project: downstream_project.full_path,
        branch: 'feature'
      }
    }
  end

  let(:bridge) do
    create(:ci_bridge, status: :pending,
                       user: user,
                       options: trigger,
                       pipeline: upstream_pipeline)
  end

  let(:service) { described_class.new(upstream_project, user) }

  before do
    stub_ci_pipeline_to_return_yaml_file
    upstream_project.add_developer(user)
  end

  context 'when downstream project has not been found' do
    let(:trigger) do
      { trigger: { project: 'unknown/project' } }
    end

    it 'does not create a pipeline' do
      expect { service.execute(bridge) }
        .not_to change { Ci::Pipeline.count }
    end

    it 'changes pipeline bridge job status to failed' do
      service.execute(bridge)

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason)
        .to eq 'downstream_bridge_project_not_found'
    end
  end

  context 'when user can not access downstream project' do
    it 'does not create a new pipeline' do
      expect { service.execute(bridge) }
        .not_to change { Ci::Pipeline.count }
    end

    it 'changes status of the bridge build' do
      service.execute(bridge)

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason)
        .to eq 'downstream_bridge_project_not_found'
    end
  end

  context 'when user does not have access to create pipeline' do
    before do
      downstream_project.add_guest(user)
    end

    it 'does not create a new pipeline' do
      expect { service.execute(bridge) }
        .not_to change { Ci::Pipeline.count }
    end

    it 'changes status of the bridge build' do
      service.execute(bridge)

      expect(bridge.reload).to be_failed
      expect(bridge.failure_reason).to eq 'insufficient_bridge_permissions'
    end
  end

  context 'when user can create pipeline in a downstream project' do
    before do
      downstream_project.add_developer(user)
    end

    it 'creates only one new pipeline' do
      expect { service.execute(bridge) }
        .to change { Ci::Pipeline.count }.by(1)
    end

    it 'creates a new pipeline in a downstream project' do
      pipeline = service.execute(bridge)

      expect(pipeline.user).to eq bridge.user
      expect(pipeline.project).to eq downstream_project
      expect(bridge.sourced_pipelines.first.pipeline).to eq pipeline
      expect(pipeline.triggered_by_pipeline).to eq upstream_pipeline
      expect(pipeline.source_bridge).to eq bridge
      expect(pipeline.source_bridge).to be_a ::Ci::Bridge
    end

    it 'updates bridge status when downstream pipeline gets proceesed' do
      pipeline = service.execute(bridge)

      expect(pipeline.reload).to be_pending
      expect(bridge.reload).to be_success
    end

    context 'when target ref is not specified' do
      let(:trigger) do
        { trigger: { project: downstream_project.full_path } }
      end

      it 'is using default branch name' do
        pipeline = service.execute(bridge)

        expect(pipeline.ref).to eq 'master'
      end
    end

    context 'when circular dependency is defined' do
      let(:trigger) do
        { trigger: { project: upstream_project.full_path } }
      end

      it 'does not create a new pipeline' do
        expect { service.execute(bridge) }
          .not_to change { Ci::Pipeline.count }
      end

      it 'changes status of the bridge build' do
        service.execute(bridge)

        expect(bridge.reload).to be_failed
        expect(bridge.failure_reason).to eq 'invalid_bridge_trigger'
      end
    end

    context 'when bridge job has YAML variables defined' do
      before do
        bridge.yaml_variables = [{ key: 'BRIDGE', value: 'var', public: true }]
      end

      it 'passes bridge variables to downstream pipeline' do
        pipeline = service.execute(bridge)

        expect(pipeline.variables.first)
          .to have_attributes(key: 'BRIDGE', value: 'var')
      end
    end

    context 'when pipeline variables are defined' do
      before do
        upstream_pipeline.variables.create(key: 'PIPELINE_VARIABLE', value: 'my-value')
      end

      it 'does not pass pipeline variables directly downstream' do
        pipeline = service.execute(bridge)

        pipeline.variables.map(&:key).tap do |variables|
          expect(variables).not_to include 'PIPELINE_VARIABLE'
        end
      end

      context 'when using YAML variables interpolation' do
        before do
          bridge.yaml_variables = [{ key: 'BRIDGE', value: '$PIPELINE_VARIABLE-var', public: true }]
        end

        it 'makes it possible to pass pipeline variable downstream' do
          pipeline = service.execute(bridge)

          pipeline.variables.find_by(key: 'BRIDGE').tap do |variable|
            expect(variable.value).to eq 'my-value-var'
          end
        end
      end
    end

    # TODO: Move this context into a feature spec that uses
    # multiple pipeline processing services. Location TBD in:
    # https://gitlab.com/gitlab-org/gitlab/issues/36216
    context 'when configured with bridge job rules' do
      before do
        stub_ci_pipeline_yaml_file(config)
        downstream_project.add_maintainer(upstream_project.owner)
      end

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

      let(:primary_pipeline) do
        Ci::CreatePipelineService.new(upstream_project, upstream_project.owner, { ref: 'master' })
          .execute(:push, save_on_errors: false)
      end

      let(:bridge)  { primary_pipeline.processables.find_by(name: 'bridge-job') }
      let(:service) { described_class.new(upstream_project, upstream_project.owner) }

      context 'that include the bridge job' do
        it 'creates the downstream pipeline' do
          expect { service.execute(bridge) }
            .to change(downstream_project.ci_pipelines, :count).by(1)
        end
      end
    end
  end
end
