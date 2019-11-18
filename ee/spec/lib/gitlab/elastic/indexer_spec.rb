# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elastic::Indexer do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
    stub_ee_application_setting(ee_application_setting) if ee_application_setting.present?
  end

  let(:ee_application_setting) { { elasticsearch_url: ['http://localhost:9200'] } }
  let(:project) { create(:project, :repository) }
  let(:expected_from_sha) { Gitlab::Git::EMPTY_TREE_ID }
  let(:to_commit) { project.commit }
  let(:to_sha) { to_commit.try(:sha) }
  let(:indexer) { described_class.new(project) }

  let(:popen_success) { [[''], 0] }
  let(:popen_failure) { [['error'], 1] }

  context 'empty project' do
    let(:project) { create(:project) }

    it 'updates the index status without running the indexing command' do
      expect_popen.never

      indexer.run

      expect_index_status(Gitlab::Git::BLANK_SHA)
    end
  end

  context 'wikis' do
    let(:project) { create(:project, :wiki_repo) }
    let(:indexer) { described_class.new(project, wiki: true) }

    before do
      project.wiki.create_page('test.md', '# term')
    end

    it 'runs the indexer with the right flags' do
      expect_popen.with(
        [
          TestEnv.indexer_bin_path,
          '--blob-type=wiki_blob',
          '--skip-commits',
          project.id.to_s,
          "#{project.wiki.repository.disk_path}.git"
        ],
        nil,
        hash_including(
          'ELASTIC_CONNECTION_INFO' => elasticsearch_config.to_json,
          'RAILS_ENV'               => Rails.env,
          'FROM_SHA'                => expected_from_sha,
          'TO_SHA'                  => nil
        )
      ).and_return(popen_success)

      indexer.run
    end

    context 'when IndexStatus#last_wiki_commit is no longer in repository', :elastic do
      let(:user) { project.owner }
      let(:ee_application_setting) { nil }

      before do
        stub_ee_application_setting(elasticsearch_indexing: true)
        ElasticIndexerWorker.new.perform('index', 'Project', project.id, project.es_id)
      end

      def change_wiki_and_index(project, &blk)
        yield blk if blk

        current_commit = project.wiki.repository.commit('master').sha

        described_class.new(project, wiki: true).run(current_commit)
        Gitlab::Elastic::Helper.refresh_index
      end

      def indexed_wiki_paths_for(term)
        blobs = ProjectWiki.elastic_search(
          term,
          type: :wiki_blob
        )[:wiki_blobs][:results].response

        blobs.map do |blob|
          blob['_source']['blob']['path']
        end
      end

      it 'reindexes from scratch' do
        sha_for_reset = nil

        change_wiki_and_index(project) do
          sha_for_reset = project.wiki.repository.create_file(user, '12', '', message: '12', branch_name: 'master')
          project.wiki.repository.create_file(user, '23', '', message: '23', branch_name: 'master')
        end

        expect(indexed_wiki_paths_for('12')).to include('12')
        expect(indexed_wiki_paths_for('23')).to include('23')

        project.index_status.update!(last_wiki_commit: '____________')

        change_wiki_and_index(project) do
          project.wiki.repository.write_ref('master', sha_for_reset)
        end

        expect(indexed_wiki_paths_for('12')).to include('12')
        expect(indexed_wiki_paths_for('23')).not_to include('23')
      end
    end
  end

  context 'repository has unborn head' do
    it 'updates the index status without running the indexing command' do
      allow(project.repository).to receive(:exists?).and_return(false)
      expect_popen.never

      indexer.run

      expect_index_status(Gitlab::Git::BLANK_SHA)
    end
  end

  context 'test project' do
    let(:project) { create(:project, :repository) }

    it 'runs the indexing command' do
      gitaly_connection_data = {
        storage: project.repository_storage
      }.merge(Gitlab::GitalyClient.connection_data(project.repository_storage))

      expect_popen.with(
        [
          TestEnv.indexer_bin_path,
          project.id.to_s,
          "#{project.repository.disk_path}.git"
        ],
        nil,
        hash_including(
          'GITALY_CONNECTION_INFO'  => gitaly_connection_data.to_json,
          'ELASTIC_CONNECTION_INFO' => elasticsearch_config.to_json,
          'RAILS_ENV'               => Rails.env,
          'FROM_SHA'                => expected_from_sha,
          'TO_SHA'                  => to_sha
        )
      ).and_return(popen_success)

      indexer.run(to_sha)
    end

    context 'when IndexStatus exists' do
      context 'when last_commit exists' do
        let(:last_commit) { to_commit.parent_ids.first }

        before do
          project.create_index_status!(last_commit: last_commit)
        end

        it 'uses last_commit as from_sha' do
          expect_popen.and_return(popen_success)

          indexer.run(to_sha)

          expect_index_status(to_sha)
        end
      end
    end

    it 'updates the index status when the indexing is a success' do
      expect_popen.and_return(popen_success)

      indexer.run(to_sha)

      expect_index_status(to_sha)
    end

    it 'leaves the index status untouched when indexing a non-HEAD commit' do
      expect_popen.and_return(popen_success)

      indexer.run(project.repository.commit('HEAD~1'))

      expect(project.index_status).to be_nil
    end

    it 'leaves the index status untouched when the indexing fails' do
      expect_popen.and_return(popen_failure)

      expect { indexer.run }.to raise_error(Gitlab::Elastic::Indexer::Error)

      expect(project.index_status).to be_nil
    end
  end

  context 'reverting a change', :elastic do
    let(:user) { project.owner }
    let!(:initial_commit) { project.repository.commit('master').sha }
    let(:ee_application_setting) { nil }

    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    def change_repository_and_index(project, &blk)
      yield blk if blk

      current_commit = project.repository.commit('master').sha

      described_class.new(project).run(current_commit)
      Gitlab::Elastic::Helper.refresh_index
    end

    def indexed_file_paths_for(term)
      blobs = Repository.elastic_search(
        term,
        type: :blob
      )[:blobs][:results].response

      blobs.map do |blob|
        blob['_source']['blob']['path']
      end
    end

    context 'when IndexStatus#last_commit is no longer in repository' do
      before do
        ElasticIndexerWorker.new.perform('index', 'Project', project.id, project.es_id)
      end

      it 'reindexes from scratch' do
        sha_for_reset = nil

        change_repository_and_index(project) do
          sha_for_reset = project.repository.create_file(user, '12', '', message: '12', branch_name: 'master')
          project.repository.create_file(user, '23', '', message: '23', branch_name: 'master')
        end

        expect(indexed_file_paths_for('12')).to include('12')
        expect(indexed_file_paths_for('23')).to include('23')

        project.index_status.update!(last_commit: '____________')

        change_repository_and_index(project) do
          project.repository.write_ref('master', sha_for_reset)
        end

        expect(indexed_file_paths_for('12')).to include('12')
        expect(indexed_file_paths_for('23')).not_to include('23')
      end
    end

    context 'when branch is reset to an earlier commit' do
      before do
        change_repository_and_index(project) do
          project.repository.create_file(user, '12', '', message: '12', branch_name: 'master')
        end

        expect(indexed_file_paths_for('12')).to include('12')
      end

      it 'reverses already indexed commits' do
        change_repository_and_index(project) do
          project.repository.write_ref('master', initial_commit)
        end

        expect(indexed_file_paths_for('12')).not_to include('12')
      end
    end
  end

  def expect_popen
    expect(Gitlab::Popen).to receive(:popen)
  end

  def expect_index_status(sha)
    status = project.index_status

    expect(status).not_to be_nil
    expect(status.indexed_at).not_to be_nil
    expect(status.last_commit).to eq(sha)
  end

  def elasticsearch_config
    config = Gitlab::CurrentSettings.elasticsearch_config.dup
    config.merge!(
      field_name_table: Elastic::Latest::GitInstanceProxy::GITALY_TRANSFORM_TABLES,
      index_name: 'gitlab-test'
    )
  end
end
