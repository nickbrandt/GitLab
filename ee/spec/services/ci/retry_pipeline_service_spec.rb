# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::RetryPipelineService do
  let_it_be(:runner) { create(:ci_runner, :instance, :online) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:service) { described_class.new(project, user) }

  before do
    project.add_developer(user)

    create(:protected_branch, :developers_can_merge,
           name: pipeline.ref, project: project)
  end

  context 'when the namespace is out of CI minutes' do
    let_it_be(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
    let_it_be(:project) { create(:project, namespace: namespace) }
    let_it_be(:private_runner) do
      create(:ci_runner, :project, :online, projects: [project],
        tag_list: ['ruby'], run_untagged: false)
    end

    before do
      create_build('rspec 1', :failed)
      create_build('rspec 2', :canceled, tag_list: ['ruby'])
    end

    it 'retries the builds with available runners' do
      service.execute(pipeline)

      expect(pipeline.statuses.count).to eq(3)
      expect(build('rspec 1')).to be_failed
      expect(build('rspec 2')).to be_pending
      expect(pipeline.reload).to be_running
    end
  end

  def build(name)
    pipeline.reload.statuses.latest.find_by(name: name)
  end

  def create_build(name, status, **opts)
    create(:ci_build, name: name, status: status, pipeline: pipeline, **opts) do |build|
      ::Ci::ProcessPipelineService.new(pipeline).execute
    end
  end
end
