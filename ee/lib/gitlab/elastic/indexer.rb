# frozen_string_literal: true

# Create a separate process, which does not load the Rails environment, to index
# each repository. This prevents memory leaks in the indexer from affecting the
# rest of the application.
module Gitlab
  module Elastic
    class Indexer
      include Gitlab::Utils::StrongMemoize

      EXPERIMENTAL_INDEXER = 'gitlab-elasticsearch-indexer'.freeze

      Error = Class.new(StandardError)

      class << self
        def experimental_indexer_present?
          Gitlab::Utils.which(EXPERIMENTAL_INDEXER).present?
        end

        def experimental_indexer_version
          Rails.root.join('GITLAB_ELASTICSEARCH_INDEXER_VERSION').read.chomp
        end
      end

      attr_reader :project, :index_status

      def initialize(project, wiki: false)
        @project = project
        @wiki = wiki

        # We accept any form of settings, including string and array
        # This is why JSON is needed
        @vars = {
          'ELASTIC_CONNECTION_INFO' => Gitlab::CurrentSettings.elasticsearch_config.to_json,
          'RAILS_ENV'               => Rails.env
        }

        if use_experimental_indexer?
          @vars['GITALY_CONNECTION_INFO'] = {
            storage: project.repository_storage
          }.merge(Gitlab::GitalyClient.connection_data(project.repository_storage)).to_json
        end

        # Use the eager-loaded association if available.
        @index_status = project.index_status
      end

      def run(to_sha = nil)
        to_sha = nil if to_sha == Gitlab::Git::BLANK_SHA

        head_commit = repository.try(:commit)

        if repository.nil? || !repository.exists? || repository.empty? || head_commit.nil?
          update_index_status(Gitlab::Git::BLANK_SHA)
          return
        end

        run_indexer!(to_sha)
        update_index_status(to_sha)

        true
      end

      private

      def wiki?
        @wiki
      end

      def repository
        wiki? ? project.wiki.repository : project.repository
      end

      def path_to_indexer
        if use_experimental_indexer?
          EXPERIMENTAL_INDEXER
        else
          Rails.root.join('bin', 'elastic_repo_indexer').to_s
        end
      end

      def use_experimental_indexer?
        strong_memoize(:use_experimental_indexer) do
          if wiki?
            raise '`gitlab-elasticsearch-indexer` is required for indexing wikis' unless self.class.experimental_indexer_present?

            true
          else
            Gitlab::CurrentSettings.elasticsearch_experimental_indexer? && self.class.experimental_indexer_present?
          end
        end
      end

      def run_indexer!(to_sha)
        if index_status && !repository_contains_last_indexed_commit?
          repository.delete_index_for_commits_and_blobs
        end

        command =
          if wiki?
            [path_to_indexer, "--blob-type=wiki_blob", "--skip-commits", project.id.to_s, repository_path]
          else
            [path_to_indexer, project.id.to_s, repository_path]
          end

        vars = @vars.merge('FROM_SHA' => from_sha, 'TO_SHA' => to_sha)

        output, status = Gitlab::Popen.popen(command, nil, vars)

        raise Error, output unless status&.zero?
      end

      def last_commit
        if wiki?
          index_status&.last_wiki_commit
        else
          index_status&.last_commit
        end
      end

      def from_sha
        repository_contains_last_indexed_commit? ? last_commit : Gitlab::Git::EMPTY_TREE_ID
      end

      def repository_contains_last_indexed_commit?
        strong_memoize(:repository_contains_last_indexed_commit) do
          last_commit.present? && repository.commit(last_commit).present?
        end
      end

      def repository_path
        # Go indexer needs relative path while ruby indexer needs absolute one
        if use_experimental_indexer?
          "#{repository.disk_path}.git"
        else
          ::Gitlab::GitalyClient::StorageSettings.allow_disk_access { repository.path_to_repo }
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def update_index_status(to_sha)
        head_commit = repository.try(:commit)

        # An index_status should always be created,
        # even if the repository is empty, so we know it's been looked at.
        @index_status ||=
          begin
            IndexStatus.find_or_create_by(project_id: project.id)
          rescue ActiveRecord::RecordNotUnique
            retry
          end

        # Don't update the index status if we never reached HEAD
        return if head_commit && to_sha && head_commit.sha != to_sha

        sha = head_commit.try(:sha)
        sha ||= Gitlab::Git::BLANK_SHA

        attributes =
          if wiki?
            { last_wiki_commit: sha, wiki_indexed_at: Time.now }
          else
            { last_commit: sha, indexed_at: Time.now }
          end

        @index_status.update(attributes)
        project.reload_index_status
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
