# frozen_string_literal: true

module Elastic
  module RepositoriesSearch
    extend ActiveSupport::Concern

    include ApplicationVersionedSearch

    included do
      delegate(:find_commits_by_message_with_elastic, :delete_index_for_commits_and_blobs, :elastic_search, to: :__elasticsearch__)

      class << self
        delegate(:find_commits_by_message_with_elastic, to: :__elasticsearch__)
      end
    end

    def index_commits_and_blobs(from_rev: nil, to_rev: nil)
      ::ElasticCommitIndexerWorker.perform_async(project.id, from_rev, to_rev)
    end
  end
end
