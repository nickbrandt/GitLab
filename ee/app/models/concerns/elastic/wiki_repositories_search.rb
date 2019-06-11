# frozen_string_literal: true

module Elastic
  module WikiRepositoriesSearch
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Git::Repository

      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')

      def repository_id
        "wiki_#{project.id}"
      end

      def es_type
        'wiki_blob'
      end

      delegate :id, to: :project, prefix: true

      def client_for_indexing
        self.__elasticsearch__.client
      end

      def index_wiki_blobs(to_sha = nil)
        if ::Gitlab::CurrentSettings.elasticsearch_experimental_indexer?
          ElasticCommitIndexerWorker.perform_async(project.id, nil, to_sha, true)
        else
          project.wiki.index_blobs
        end
      end

      def self.import
        Project.with_wiki_enabled.find_each do |project|
          if project.use_elasticsearch? && !project.wiki.empty?
            project.wiki.index_wiki_blobs
          end
        end
      end
    end
  end
end
