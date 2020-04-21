# frozen_string_literal: true

require 'rake_helper'

describe 'gitlab:elastic namespace rake tasks', :elastic do
  before do
    Rake.application.rake_require 'tasks/gitlab/elastic'
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  describe 'index' do
    it 'calls all indexing tasks in order' do
      expect(Rake::Task['gitlab:elastic:recreate_index']).to receive(:invoke).ordered
      expect(Rake::Task['gitlab:elastic:clear_index_status']).to receive(:invoke).ordered
      expect(Rake::Task['gitlab:elastic:index_projects']).to receive(:invoke).ordered
      expect(Rake::Task['gitlab:elastic:index_snippets']).to receive(:invoke).ordered

      run_rake_task 'gitlab:elastic:index'
    end
  end

  describe 'index_projects' do
    let(:project1) { create :project }
    let(:project2) { create :project }
    let(:project3) { create :project }

    before do
      Sidekiq::Testing.disable! do
        project1
        project2
      end
    end

    it 'queues jobs for each project batch' do
      expect(ElasticIndexerWorker).to receive(:bulk_perform_async).with([
        [:index, 'Project', project1.id, nil],
        [:index, 'Project', project2.id, nil]
      ])

      run_rake_task 'gitlab:elastic:index_projects'
    end

    context 'with limited indexing enabled' do
      before do
        Sidekiq::Testing.disable! do
          project1
          project2
          project3

          create :elasticsearch_indexed_project, project: project1
          create :elasticsearch_indexed_namespace, namespace: project3.namespace
        end

        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      it 'does not queue jobs for projects that should not be indexed' do
        expect(ElasticIndexerWorker).to receive(:bulk_perform_async).with([
          [:index, 'Project', project1.id, nil],
          [:index, 'Project', project3.id, nil]
        ])

        run_rake_task 'gitlab:elastic:index_projects'
      end
    end
  end

  describe 'index_snippets' do
    it 'indexes snippets' do
      expect(Snippet).to receive(:es_import)

      run_rake_task 'gitlab:elastic:index_snippets'
    end
  end

  describe 'recreate_index' do
    it 'calls all related subtasks in order' do
      expect(Rake::Task['gitlab:elastic:delete_index']).to receive(:invoke).ordered
      expect(Rake::Task['gitlab:elastic:create_empty_index']).to receive(:invoke).ordered

      run_rake_task 'gitlab:elastic:recreate_index'
    end
  end
end
