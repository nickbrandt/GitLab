require 'spec_helper'

describe Ci::ProcessPipelineService, '#execute' do
  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }
  set(:downstream) { create(:project, :repository) }

  set(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project, user: user)
  end

  before do
    project.add_maintainer(user)
    downstream.add_developer(user)
  end

  describe 'cross-project pipelines' do
    before do
      create_processable(:ci_build, name: 'test', stage: 'test')
      create_processable(:ci_bridge, name: 'cross',
                                     stage: 'build',
                                     downstream: downstream)
      create_processable(:ci_build, name: 'deploy', stage: 'deploy')

      stub_ci_pipeline_to_return_yaml_file
    end

    it 'creates a downstream cross-project pipeline' do
      pipeline.process!

      expect_statuses(%w[test pending], %w[cross created], %w[deploy created])

      update_build_status(:test, :success)

      expect_statuses(%w[test success], %w[cross success], %w[deploy pending])

      expect(downstream.ci_pipelines).to be_one
      expect(downstream.ci_pipelines.first).to be_pending
    end
  end

  def expect_statuses(*statuses)
    statuses.each do |name, status|
      pipeline.statuses.find_by(name: name).yield_self do |build|
        expect(build.status).to eq status
      end
    end
  end

  def update_build_status(name, status)
    pipeline.builds.find_by(name: name).public_send(status)
  end

  def create_processable(type, name:, **opts)
    stages = %w[test build deploy]
    index = stages.index(opts.fetch(:stage, 'test'))

    create(type, status: :created,
                 name: name,
                 pipeline: pipeline,
                 stage_idx: index,
                 user: user,
                 **opts)
  end
end
