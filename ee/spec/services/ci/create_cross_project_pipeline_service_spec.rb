require 'spec_helper'

describe Ci::CreateCrossProjectPipelineService, '#execute' do
  set(:upstream_project) { create(:project, :repository) }
  set(:downstream_project) { create(:project, :repository) }
  set(:upstream_pipeline) { create(:ci_pipeline, project: upstream_project) }
  set(:user) { create(:user) }

  let(:trigger) do
    { trigger: {
        project: downstream_project.full_path,
        branch: 'feature'
      }
    }
  end

  let(:bridge) do
    create(:ci_bridge, user: user,
                       options: trigger,
                       pipeline: upstream_pipeline)
  end


  let(:service) { described_class.new(upstream_project, user) }

  before do
    stub_ci_pipeline_to_return_yaml_file
    upstream_project.add_developer(user)
  end

  context 'when user does not have ability to create a pipeline' do
    it 'changes status of the bridge build' do
      expect { service.execute(bridge) }
        .not_to change { Ci::Pipeline.count }

      expect(bridge).to be_failed
      expect(bridge.failure_reason).to eq 'insufficient_permissions'
    end
  end

  context 'when user can create pipeline in a downstream project' do
    before do
      downstream_project.add_developer(user)
    end

    it 'creates a new pipeline' do
      expect { service.execute(bridge) }
        .to change { Ci::Pipeline.count }.by(1)
    end

    it 'creates a new pipeline in a downstream project' do
      pipeline = service.execute(bridge)

      expect(pipeline.project).to eq downstream_project
      expect(bridge.sourced_pipelines.first.pipeline).to eq pipeline
      expect(pipeline.source_pipeline.source_pipeline).to eq upstream_pipeline
      expect(pipeline.source_pipeline.source_job).to eq bridge
    end

    it 'delegates permissions to newly created pipelines' do
      pipeline = service.execute(bridge)

      expect(pipeline.user).to eq bridge.user
    end
  end
end
