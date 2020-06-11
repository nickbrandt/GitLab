# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticBatchProjectIndexerWorker do
  subject(:worker) { described_class.new }

  let(:projects) { create_list(:project, 2) }

  describe '#perform' do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    context 'with elasticsearch only enabled for a particular project' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
        create :elasticsearch_indexed_project, project: projects.first
      end

      it 'only indexes the enabled project' do
        projects.each { |project| expect_index(project).and_call_original }

        expect(Gitlab::Elastic::Indexer).to receive(:new).with(projects.first).and_return(double(run: true))
        expect(Gitlab::Elastic::Indexer).not_to receive(:new).with(projects.last)

        worker.perform(projects.first.id, projects.last.id)
      end
    end

    it 'runs the indexer for projects in the batch range' do
      projects.each { |project| expect_index(project) }

      worker.perform(projects.first.id, projects.last.id)
    end

    it 'skips projects not in the batch range' do
      expect_index(projects.first).never
      expect_index(projects.last)

      worker.perform(projects.last.id, projects.last.id)
    end

    it 'clears the "locked" state from redis when the project finishes indexing' do
      Gitlab::Redis::SharedState.with { |redis| redis.sadd(:elastic_projects_indexing, projects.first.id) }

      expect_index(projects.first).and_call_original
      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run)
      end

      expect { worker.perform(projects.first.id, projects.first.id) }
        .to change { project_locked?(projects.first) }.from(true).to(false)
    end

    it 'reindexes projects that were already indexed' do
      expect_index(projects.first)
      expect_index(projects.last)

      worker.perform(projects.first.id, projects.last.id)
    end

    it 'indexes all projects it receives even if already indexed', :sidekiq_might_not_need_inline do
      expect_index(projects.first).and_call_original
      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run)
      end

      worker.perform(projects.first.id, projects.first.id)
    end
  end

  def expect_index(project)
    expect(worker).to receive(:run_indexer).with(project)
  end

  def project_locked?(project)
    Gitlab::Redis::SharedState.with { |redis| redis.sismember(:elastic_projects_indexing, project.id) }
  end
end
