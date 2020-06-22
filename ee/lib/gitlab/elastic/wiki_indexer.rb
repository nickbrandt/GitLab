# frozen_string_literal: true

module Gitlab
  module Elastic
    class ProjectWikiOperation < ProjectOperation
      def last_commit
        index_status&.last_wiki_commit
      end

      def repository
        project.wiki.repository
      end

      def index_status_update(last_commit:, indexed_at:)
        { last_wiki_commit: last_commit, wiki_indexed_at: indexed_at }
      end

      def purge_from_index!
        repository.__elasticsearch__.elastic_writing_targets.each do |t|
          t.delete_index_for_commits_and_blobs(wiki: true)
        end
      end
    end

    class WikiIndexer < Indexer
      def operation_for(project)
        ProjectWikiOperation.new(project)
      end

      def arguments
        super.merge(
          blob_type: "wiki_blob",
          skip_commits: true
        )
      end
    end
  end
end
