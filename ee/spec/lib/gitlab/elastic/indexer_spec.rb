# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::ProjectOperation do
  let(:project) { create(:project, :repository) }

  subject(:operation) { described_class.new(project) }

  describe '#find_indexable_commit' do
    it 'is truthy for reachable commits' do
      expect(operation.find_indexable_commit(project.repository.commit.sha)).to be_an_instance_of(::Commit)
    end

    it 'is falsey for unreachable commits', :aggregate_failures do
      expect(operation.find_indexable_commit(Gitlab::Git::BLANK_SHA)).to be_nil
      expect(operation.find_indexable_commit(Gitlab::Git::EMPTY_TREE_ID)).to be_nil
    end
  end
end

module Process
  class StatusMock
    attr_reader :exitstatus

    def success?
      exitstatus == 0
    end

    class OK < self
      def initialize
        @exitstatus = 0
      end
    end

    class Error < self
      def initialize
        @exitstatus = 1
      end
    end
  end
end

RSpec.describe Gitlab::Elastic::Indexer do
  include StubENV

  before do
    RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 10000000
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
  end

  let(:project) { create(:project, :repository) }
  let(:expected_from_sha) { Gitlab::Git::EMPTY_TREE_ID }
  let(:to_commit) { project.commit }
  let(:to_sha) { to_commit.try(:sha) }

  def results_spec(indexer, error_code: 0)
    indexer.operations.values.map do |op|
      # Return the latest indexed SHA
      [op.project.id, op.repository_path, op.repository.commit.sha, error_code].join("\t")
    end
  end

  def popen_success(indexer)
    Gitlab::Popen::Result.new('/dev/null',
                              results_spec(indexer, error_code: 0).join("\n"),
                              '',
                              Process::StatusMock::OK.new,
                              1.second)
  end

  def popen_failure(indexer)
    Gitlab::Popen::Result.new('/dev/null',
                              results_spec(indexer, error_code: 1).join("\n"),
                              'error',
                              Process::StatusMock::Error.new,
                              1.second)
  end

  subject(:indexer) do
    described_class.new(project)
  end

  context 'empty project', :elastic do
    let(:project) { create(:project) }

    it 'ignores the indexing command' do
      expect_popen.never

      indexer.flush
    end
  end

  context 'with an indexed project', :elastic do
    let(:head) { project.repository.commit.sha }

    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    shared_examples 'index up to the specified commit' do
      it 'updates the index status when the indexing is a success' do
        expect_popen.and_return(popen_success(indexer))

        indexer.flush

        expect_index_status(head)
      end

      it 'leaves the index status untouched when the indexing fails' do
        expect_popen.and_return(popen_failure(indexer))

        expect(indexer.flush).to contain_exactly(project)

        expect(project.index_status).to be_nil
      end
    end

    context 'when indexing a descendant commit', :elastic do
      it_behaves_like 'index up to the specified commit'

      it 'runs the indexing command' do
        gitaly_connection_data = Gitlab::GitalyClient
                                   .connection_data(project.repository_storage)
                                   .merge(storage: project.repository_storage)

        expect_popen.with(
          [
            TestEnv.indexer_bin_path,
            "--blob-type", "blob",
            "--input-file", "/dev/stdin"
          ],
          nil,
          hash_including(
            'GITALY_CONNECTION_INFO'  => gitaly_connection_data.to_json,
            'ELASTIC_CONNECTION_INFO' => Gitlab::CurrentSettings.elasticsearch_config.to_json,
            'RAILS_ENV'               => Rails.env,
            'CORRELATION_ID'          => Labkit::Correlation::CorrelationId.current_id
          )
        ).and_return(popen_success(indexer))

        indexer.flush
      end

      context 'when IndexStatus exists' do
        context 'when last_commit exists' do
          let(:last_commit) { to_commit.parent_ids.first }

          before do
            project.create_index_status!(last_commit: last_commit)
          end

          it 'uses last_commit as from_sha' do
            expect_popen.and_return(popen_success(indexer))

            indexer.flush

            expect_index_status(to_sha)
          end
        end
      end
    end

    context 'when indexing a non-descendant commit', :elastic do
      let(:head) { project.repository.commit('HEAD~1').sha }

      context 'after reverting a change' do
        let(:user) { project.owner }
        let!(:initial_commit) { project.repository.commit('master').sha }

        def change_repository_and_index(project, &blk)
          yield blk if blk

          indexer.process(project).flush
          ensure_elasticsearch_index!
        end

        def indexed_file_paths_for(term)
          blobs = Repository.elastic_search(
            term,
            type: 'blob'
          )[:blobs][:results].response

          blobs.map do |blob|
            blob['_source']['blob']['path']
          end
        end

        def indexed_commits_for(term)
          commits = Repository.elastic_search(
            term,
            type: 'commit'
          )[:commits][:results].response

          commits.map do |commit|
            commit['_source']['commit']['sha']
          end
        end

        context 'when IndexStatus#last_commit is no longer in repository' do
          it 'reindexes from scratch' do
            sha_for_reset = nil

            change_repository_and_index(project) do
              sha_for_reset = project.repository.create_file(user, '12', '', message: '12', branch_name: 'master')
              project.repository.create_file(user, '23', '', message: '23', branch_name: 'master')
            end

            expect(indexed_file_paths_for('12')).to include('12')
            expect(indexed_file_paths_for('23')).to include('23')

            # set the index_status to a bogus commit
            IndexStatus.upsert({
                                 project_id: project.id,
                                 last_commit: '____________',
                                 created_at: Time.now,
                                 updated_at: Time.now
                               },
                               unique_by: :project_id)

            change_repository_and_index(project) do
              project.repository.write_ref('master', sha_for_reset)
            end

            expect(indexed_file_paths_for('12')).to include('12')
            expect(indexed_file_paths_for('23')).not_to include('23')
          end
        end

        context 'when branch is reset to an earlier commit' do
          it 'reverses already indexed commits' do
            change_repository_and_index(project) do
              project.repository.create_file(user, '12', '', message: '12', branch_name: 'master')
            end

            head = project.repository.commit.sha

            expect(indexed_commits_for('12')).to include(head)
            expect(indexed_file_paths_for('12')).to include('12')

            # resetting the repository should purge the index of the outstanding commits
            change_repository_and_index(project) do
              project.repository.write_ref('master', initial_commit)
            end

            expect(indexed_commits_for('12')).not_to include(head)
            expect(indexed_file_paths_for('12')).not_to include('12')
          end
        end
      end
    end

    context "when indexing a project's wiki", :elastic do
      let(:project) { create(:project, :wiki_repo) }
      let(:indexer) { ::Gitlab::Elastic::WikiIndexer.new(project) }
      let(:to_sha) { project.wiki.repository.commit('master').sha }

      before do
        project.wiki.create_page('test.md', '# term')
      end

      it 'runs the indexer with the right flags' do
        expect_popen.with(
          [
            TestEnv.indexer_bin_path,
            '--blob-type', 'wiki_blob',
            '--skip-commits',
            '--input-file', '/dev/stdin'
          ],
          nil,
          hash_including(
            'ELASTIC_CONNECTION_INFO' => Gitlab::CurrentSettings.elasticsearch_config.to_json,
            'RAILS_ENV'               => Rails.env
          )
        ).and_return(popen_success(indexer))

        indexer.flush
      end

      context 'when IndexStatus#last_wiki_commit is no longer in repository' do
        let(:user) { project.owner }

        def change_wiki_and_index(project, &blk)
          yield blk if blk

          indexer.process(project).flush
          ensure_elasticsearch_index!
        end

        def indexed_wiki_paths_for(term)
          blobs = ProjectWiki.elastic_search(
            term,
            type: 'wiki_blob'
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

          # set the index_status to a bogus commit
          IndexStatus.upsert({
                               project_id: project.id,
                               last_wiki_commit: '____________',
                               created_at: Time.now,
                               updated_at: Time.now
                             },
                             unique_by: :project_id)

          change_wiki_and_index(project) do
            project.wiki.repository.write_ref('master', sha_for_reset)
          end

          expect(indexed_wiki_paths_for('12')).to include('12')
          expect(indexed_wiki_paths_for('23')).not_to include('23')
        end
      end
    end
  end

  context 'when SSL env vars are not set explicitly' do
    let(:ruby_cert_file) { OpenSSL::X509::DEFAULT_CERT_FILE }
    let(:ruby_cert_dir) { OpenSSL::X509::DEFAULT_CERT_DIR }

    subject { envvars }

    it 'they will be set to default values determined by Ruby' do
      is_expected.to include('SSL_CERT_FILE' => ruby_cert_file, 'SSL_CERT_DIR' => ruby_cert_dir)
    end
  end

  context 'when SSL env vars are set' do
    let(:cert_file) { '/fake/cert.pem' }
    let(:cert_dir) { '/fake/cert/dir' }

    before do
      stub_env('SSL_CERT_FILE', cert_file)
      stub_env('SSL_CERT_DIR', cert_dir)
    end

    context 'when building env vars for child process' do
      subject { envvars }

      it 'SSL env vars will be included' do
        is_expected.to include('SSL_CERT_FILE' => cert_file, 'SSL_CERT_DIR' => cert_dir)
      end
    end
  end

  def ref(record)
    Gitlab::Elastic::DocumentReference.build(record)
  end

  def expect_popen
    expect(Gitlab::Popen).to receive(:popen_with_detail)
  end

  def expect_index_status(sha)
    status = project.index_status

    expect(status).not_to be_nil
    expect(status.indexed_at).not_to be_nil
    expect(status.last_commit).to eq(sha)
  end

  def envvars
    indexer.send(:build_envvars, gitaly_storage: project.repository_storage)
  end
end
