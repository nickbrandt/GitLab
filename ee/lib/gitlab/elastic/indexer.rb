# frozen_string_literal: true

# Create a separate process, which does not load the Rails environment, to index
# each repository. This prevents memory leaks in the indexer from affecting the
# rest of the application.
module Gitlab
  module Elastic
    class Indexer
      include Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)

      class << self
        def indexer_version
          Rails.root.join('GITLAB_ELASTICSEARCH_INDEXER_VERSION').read.chomp
        end
      end

      attr_reader :project, :index_status

      def initialize(project, wiki: false)
        @project = project
        @wiki = wiki

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

        repository.__elasticsearch__.elastic_writing_targets.each do |target|
          run_indexer!(to_sha, target)
        end
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

      def run_indexer!(to_sha, target)
        # We accept any form of settings, including string and array
        # This is why JSON is needed
        vars = {
          'RAILS_ENV'               => Rails.env,
          'ELASTIC_CONNECTION_INFO' => elasticsearch_config(target),
          'GITALY_CONNECTION_INFO'  => gitaly_connection_info,
          'FROM_SHA'                => from_sha,
          'TO_SHA'                  => to_sha
        }

        if index_status && !repository_contains_last_indexed_commit?
          target.delete_index_for_commits_and_blobs(wiki: wiki?)
        end

        path_to_indexer = Gitlab.config.elasticsearch.indexer_path

        command =
          if wiki?
            [path_to_indexer, "--blob-type=wiki_blob", "--skip-commits", project.id.to_s, repository_path]
          else
            [path_to_indexer, project.id.to_s, repository_path]
          end

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
        "#{repository.disk_path}.git"
      end

      def elasticsearch_config(target)
        config = Gitlab::CurrentSettings.elasticsearch_config.dup
        config[:transform_tables] = target.real_class::GITALY_TRANSFORM_TABLES
        config[:index_name] = target.index_name
        config.to_json
      end

      def gitaly_connection_info
        {
          storage: project.repository_storage
        }.merge(Gitlab::GitalyClient.connection_data(project.repository_storage)).to_json
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
