# frozen_string_literal: true

# Create a separate process, which does not load the Rails environment, to index
# each repository. This prevents memory leaks in the indexer from affecting the
# rest of the application.
module Gitlab
  module Elastic
    class ProjectOperation
      include Gitlab::Utils::StrongMemoize

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def index_status
        @project.index_status
      end

      def last_commit
        index_status&.last_commit
      end

      def from_sha
        strong_memoize(:from_sha) do
          repository_contains_last_indexed_commit? ? last_commit : Gitlab::Git::EMPTY_TREE_ID
        end
      end

      def repository_contains_last_indexed_commit?
        strong_memoize(:repository_contains_last_indexed_commit) do
          last_commit.present? && repository.commit(last_commit).present?
        end
      end

      def last_commit_ancestor_of?(to_sha)
        return true if from_sha == Gitlab::Git::BLANK_SHA
        return false unless repository_contains_last_indexed_commit?

        # we always treat the `EMPTY_TREE_ID` as an ancestor to make sure
        # we don't try to purge an empty index
        from_sha == Gitlab::Git::EMPTY_TREE_ID || repository.ancestor?(from_sha, to_sha)
      end

      def find_indexable_commit(ref = 'HEAD')
        !repository.empty? && repository.commit(ref)
      end

      def repository
        project.repository
      end

      def repository_path
        "#{repository.disk_path}.git"
      end

      def repository_storage
        repository.storage
      end

      def index_status_update(last_commit:, indexed_at:)
        { last_commit: last_commit, indexed_at: indexed_at }
      end

      def purge_from_index!
        repository.__elasticsearch__.elastic_writing_targets.each do |t|
          t.delete_index_for_commits_and_blobs(wiki: false)
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def update_index_status(to_sha)
        raise "Invalid sha #{to_sha}" unless to_sha.present?

        # An index_status should always be created,
        # even if the repository is empty, so we know it's been looked at.
        @index_status ||=
          begin
            IndexStatus.find_or_create_by(project_id: project.id)
          rescue ActiveRecord::RecordNotUnique
            retry
          end

        attributes = index_status_update(last_commit: to_sha, indexed_at: Time.now)
        @index_status.update(attributes)

        project.reload_index_status
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    class Indexer
      Error = Class.new(StandardError)

      class << self
        def indexer_version
          Rails.root.join('GITLAB_ELASTICSEARCH_INDEXER_VERSION').read.chomp
        end

        def logger
          ::Gitlab::Elasticsearch::Logger.build
        end
      end

      attr_reader :operations, :failures

      def initialize(*projects)
        @operations = {}
        @failures = []

        projects.each { |p| process(p) }
      end

      def operation_for(project)
        ProjectOperation.new(project)
      end

      def process(ref)
        case ref
        when Project
          @operations[ref.id] = operation_for(ref)
        when DocumentReference
          if ref.klass == Project && ref.database_record
            @operations[ref.db_id] = operation_for(ref.database_record)
          end
        end

        self
      end

      def flush
        clean! do
          @operations.values.group_by(&:repository_storage).each do |storage, group|
            run_indexer!(group, gitaly_storage: storage)
          end
        rescue Error => e
          Gitlab::ErrorTracking.track_exception(e)

          # treat the whole batch as failed
          @failures = @operations.values.map(&:project)
        end

        failures
      end

      alias_method :run, :flush

      private

      def prepare_operations!(operations)
        operations.map do |op|
          commit = op.find_indexable_commit
          next unless commit

          # This might happen when default branch has been reset or rebased.
          base_sha = if purge_unreachable_commits_from_index!(op, commit.sha)
                       Gitlab::Git::EMPTY_TREE_ID
                     else
                       op.from_sha
                     end

          [op.project.id, op.repository_path, base_sha].join("\t")
        end.compact
      end

      def clean!(&block)
        @failures = []
        yield
      ensure
        @operations = {}
      end

      # Runs the indexation process, which is the following:
      # - Purge the index for any unreachable commits;
      # - Run the `gitlab-elasticsearch-indexer`;
      # - Update the `index_status` for the associated project;
      #
      # ref - Git ref up to which the indexation will run (default: HEAD)
      def run_indexer!(operations, gitaly_storage:)
        vars = build_envvars(gitaly_storage: gitaly_storage)
        specs = prepare_operations!(operations)

        logger.info(class: self.class.name, message: "Indexing canceled, nothing to do") && return if specs.empty?

        result = gitlab_elasticsearch_indexer(env: vars) do |stdin|
          specs.each { |spec| stdin << spec << "\n" }
        end

        raise Error, result.stderr unless result.status.success?

        # A better approach here would be to read asynchronously from
        # STDOUT and processing each result as a stream.
        result.stdout.split("\n").each { |spec| process_result(spec) }

        failures
      end

      def process_result(spec)
        project_id, _, indexed_sha, error = spec.split("\t")
        op = @operations[project_id.to_i]

        case error.to_i
        when 0
          op.update_index_status(indexed_sha)
        when 1..2
          @failures << op.project
        end
      rescue => e
        Gitlab::ErrorTracking.track_exception(e)
      end

      def gitlab_elasticsearch_indexer(env: {}, &block)
        command = [Gitlab.config.elasticsearch.indexer_path]
        command << "--blob-type" << arguments[:blob_type] if arguments[:blob_type]
        command << "--skip-commits" if arguments[:skip_commits]
        command << "--input-file" << arguments[:input_file] if arguments[:input_file]

        logger.debug(command)

        Gitlab::Popen.popen_with_detail(command, nil, env, &block)
      end

      def arguments
        {
          blob_type: "blob",
          input_file: "/dev/stdin"
        }
      end

      # Remove all indexed data for commits and blobs for a project.
      #
      # @return: whether the index has been purged
      def purge_unreachable_commits_from_index!(op, to_sha)
        return false if op.last_commit_ancestor_of?(to_sha)

        logger.info("Purging #{op.project.id} from index.")
        op.purge_from_index!

        true
      rescue ::Elasticsearch::Transport::Transport::Errors::BadRequest => e
        Gitlab::ErrorTracking.track_exception(e, project_id: op.project.id)

        raise Error, e.message
      end

      def build_envvars(gitaly_storage:)
        # We accept any form of settings, including string and array
        # This is why JSON is needed
        vars = {
          'RAILS_ENV'               => Rails.env,
          'ELASTIC_CONNECTION_INFO' => Gitlab::CurrentSettings.elasticsearch_config.to_json,
          'GITALY_CONNECTION_INFO'  => gitaly_connection_info(gitaly_storage).to_json,
          'CORRELATION_ID'          => Labkit::Correlation::CorrelationId.current_id,
          'SSL_CERT_FILE'           => OpenSSL::X509::DEFAULT_CERT_FILE,
          'SSL_CERT_DIR'            => OpenSSL::X509::DEFAULT_CERT_DIR
        }

        # Users can override default SSL certificate path via these envs
        %w(SSL_CERT_FILE SSL_CERT_DIR).each_with_object(vars) do |key, hash|
          hash[key] = ENV[key] if ENV.key?(key)
        end
      end

      def gitaly_connection_info(storage)
        Gitlab::GitalyClient.connection_data(storage).merge(storage: storage)
      end

      def logger
        self.class.logger
      end
    end
  end
end
