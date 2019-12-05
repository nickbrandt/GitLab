# frozen_string_literal: true

module Elastic
  module WikiRepositoriesSearch
    extend ActiveSupport::Concern

    include ApplicationVersionedSearch

    delegate(:delete_index_for_commits_and_blobs, :elastic_search, to: :__elasticsearch__)

    def index_wiki_blobs(to_sha = nil)
      ElasticCommitIndexerWorker.perform_async(project.id, nil, to_sha, true)
    end
  end
end
