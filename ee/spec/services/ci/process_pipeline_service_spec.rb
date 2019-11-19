# frozen_string_literal: true

require 'spec_helper'

describe Ci::ProcessPipelineService, '#execute' do
  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }
  set(:downstream) { create(:project, :repository) }

  set(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project, user: user)
  end

  let(:service) { described_class.new(pipeline) }

  before do
    project.add_maintainer(user)
    downstream.add_developer(user)
  end

  describe 'cross-project pipelines' do
    before do
      create_processable(:build, name: 'test', stage: 'test')
      create_processable(:bridge, :variables,  name: 'cross',
                                               stage: 'build',
                                               downstream: downstream)
      create_processable(:build, name: 'deploy', stage: 'deploy')

      stub_ci_pipeline_to_return_yaml_file
    end

    it 'creates a downstream cross-project pipeline', :sidekiq_might_not_need_inline do
      service.execute

      expect_statuses(%w[test pending], %w[cross created], %w[deploy created])

      update_build_status(:test, :success)

      expect_statuses(%w[test success], %w[cross success], %w[deploy pending])

      expect(downstream.ci_pipelines).to be_one
      expect(downstream.ci_pipelines.first).to be_pending
      expect(downstream.builds).not_to be_empty
      expect(downstream.builds.first.variables)
        .to include(key: 'BRIDGE', value: 'cross', public: false, masked: false)
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

  def create_processable(type, *traits, **opts)
    stages = %w[test build deploy]
    index = stages.index(opts.fetch(:stage, 'test'))

    create("ci_#{type}", *traits, status: :created,
                                  pipeline: pipeline,
                                  stage_idx: index,
                                  user: user,
                                  **opts)
  end
end
