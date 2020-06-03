# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  subject(:execute) { service.execute(:push) }

  let_it_be(:downstream_project) { create(:project, name: 'project', namespace: create(:namespace, name: 'some')) }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:admin) }
  let(:service) { described_class.new(project, user, { ref: 'refs/heads/master' }) }

  let(:config) do
    <<~EOY
    regular_job:
      stage: build
      script:
        - echo 'hello'
    bridge_dag_job:
      stage: test
      needs:
        - regular_job
      trigger: 'some/project'
    EOY
  end

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  it 'persists pipeline' do
    expect(execute).to be_persisted
  end

  it 'persists both jobs' do
    expect { execute }.to change(Ci::Build, :count).from(0).to(1)
      .and change(Ci::Bridge, :count).from(0).to(1)
  end

  it 'persists bridge needs' do
    job = execute.builds.first
    bridge = execute.stages.last.bridges.first

    expect(bridge.needs.first.name).to eq(job.name)
  end

  it 'persists bridge target project' do
    bridge = execute.stages.last.bridges.first

    expect(bridge.downstream_project).to eq downstream_project
  end

  it "sets scheduling_type of bridge_dag_job as 'dag'" do
    bridge = execute.stages.last.bridges.first

    expect(bridge.scheduling_type).to eq('dag')
  end

  context 'when needs is empty array' do
    let(:config) do
      <<~YAML
        regular_job:
          stage: build
          script: echo 'hello'
        bridge_dag_job:
          stage: test
          needs: []
          trigger: 'some/project'
      YAML
    end

    it 'creates a pipeline with regular_job and bridge_dag_job pending' do
      processables = execute.processables

      regular_job = processables.find { |processable| processable.name == 'regular_job' }
      bridge_dag_job = processables.find { |processable| processable.name == 'bridge_dag_job' }

      expect(execute).to be_persisted
      expect(regular_job.status).to eq('pending')
      expect(bridge_dag_job.status).to eq('pending')
    end
  end
end
