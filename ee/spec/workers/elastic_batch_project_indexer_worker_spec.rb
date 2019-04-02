require 'spec_helper'

describe ElasticBatchProjectIndexerWorker do
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
        projects.each { |project| expect_index(project, false).and_call_original }

        expect(Gitlab::Elastic::Indexer).to receive(:new).with(projects.first).and_return(double(run: true))
        expect(Gitlab::Elastic::Indexer).not_to receive(:new).with(projects.last)

        worker.perform(projects.first.id, projects.last.id)
      end
    end

    it 'runs the indexer for projects in the batch range' do
      projects.each { |project| expect_index(project, false) }

      worker.perform(projects.first.id, projects.last.id)
    end

    it 'skips projects not in the batch range' do
      expect_index(projects.first, false).never
      expect_index(projects.last, false)

      worker.perform(projects.last.id, projects.last.id)
    end

    it 'clears the "locked" state from redis when the project finishes indexing' do
      Gitlab::Redis::SharedState.with { |redis| redis.sadd(:elastic_projects_indexing, projects.first.id) }

      expect_index(projects.first, false).and_call_original
      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run)
      end

      expect { worker.perform(projects.first.id, projects.first.id) }
        .to change { project_locked?(projects.first) }.from(true).to(false)
    end

    context 'update_index = false' do
      it 'indexes all projects it receives even if already indexed' do
        projects.first.index_status.update!(last_commit: 'foo')

        expect_index(projects.first, false).and_call_original
        expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          expect(indexer).to receive(:run)
        end

        worker.perform(projects.first.id, projects.first.id)
      end
    end

    context 'with update_index' do
      it 'reindexes projects that were already indexed' do
        expect_index(projects.first, true)
        expect_index(projects.last, true)

        worker.perform(projects.first.id, projects.last.id, true)
      end

      it 'starts indexing at the last indexed commit' do
        projects.first.index_status.update!(last_commit: 'foo')

        expect_index(projects.first, true).and_call_original
        expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run)

        worker.perform(projects.first.id, projects.first.id, true)
      end
    end
  end

  def expect_index(project, update_index)
    expect(worker).to receive(:run_indexer).with(project, update_index)
  end

  def project_locked?(project)
    Gitlab::Redis::SharedState.with { |redis| redis.sismember(:elastic_projects_indexing, project.id) }
  end
end
